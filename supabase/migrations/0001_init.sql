-- 하차각 콘솔 초기 스키마.
--
-- 원칙
--   - 앱(anon)은 공지·원격설정을 "읽기만", 제보·이벤트는 "쓰기만" 한다.
--   - 관리자(admins 테이블에 있는 로그인 계정)만 전체 접근.
--   - 나중에 앱이 늘어도 한 콘솔에서 다루도록 모든 테이블에 app 컬럼을 둔다.
--     (현재는 'hachagak' 하나)
--   - 역 이름·경로·위치 같은 개인 이동 정보는 저장하지 않는다.

-- ---------------------------------------------------------------------------
-- 관리자
-- ---------------------------------------------------------------------------
create table public.admins (
  user_id uuid primary key references auth.users on delete cascade,
  created_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

-- ---------------------------------------------------------------------------
-- 공지 (앱이 읽음)
-- ---------------------------------------------------------------------------
create table public.notices (
  id bigint generated always as identity primary key,
  app text not null default 'hachagak',
  title text not null,
  body text not null,
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 원격 설정 (앱이 읽음) — key/value
-- ---------------------------------------------------------------------------
create table public.app_config (
  app text not null default 'hachagak',
  key text not null,
  value jsonb not null,
  description text,
  updated_at timestamptz not null default now(),
  primary key (app, key)
);

insert into public.app_config (app, key, value, description) values
  ('hachagak', 'min_version', '"0.3.0"', '이보다 낮으면 강제 업데이트'),
  ('hachagak', 'latest_version', '"0.3.0"', '이보다 낮으면 업데이트 권장'),
  ('hachagak', 'realtime_enabled', 'true', '방법 A(실시간 열차 매칭) 긴급 OFF 스위치');

-- ---------------------------------------------------------------------------
-- 제보 (앱이 쓰기만)
-- ---------------------------------------------------------------------------
create table public.feedback (
  id bigint generated always as identity primary key,
  app text not null default 'hachagak',
  device_id uuid,
  app_version text,
  os text,
  category text not null default 'bug' check (category in ('bug', 'idea', 'etc')),
  message text not null check (char_length(message) between 1 and 2000),
  status text not null default 'new' check (status in ('new', 'checking', 'done')),
  admin_note text,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 이벤트 (앱이 쓰기만) — trip_started / alert_fired / trip_ended
-- ---------------------------------------------------------------------------
create table public.events (
  id bigint generated always as identity primary key,
  app text not null default 'hachagak',
  device_id uuid,
  app_version text,
  name text not null check (name in ('trip_started', 'alert_fired', 'trip_ended')),
  props jsonb not null default '{}',
  occurred_at timestamptz not null,
  created_at timestamptz not null default now()
);

create index events_app_occurred_idx on public.events (app, occurred_at);
create index feedback_app_status_idx on public.feedback (app, status, created_at desc);

-- updated_at 자동 갱신
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

create trigger notices_touch before update on public.notices
  for each row execute function public.touch_updated_at();
create trigger app_config_touch before update on public.app_config
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.admins enable row level security;
alter table public.notices enable row level security;
alter table public.app_config enable row level security;
alter table public.feedback enable row level security;
alter table public.events enable row level security;

create policy admins_self_read on public.admins
  for select to authenticated using (user_id = auth.uid());

-- 공지: 누구나 "게시 중인 것"만 읽기, 관리자는 전부
create policy notices_public_read on public.notices
  for select to anon, authenticated
  using (starts_at <= now() and (ends_at is null or ends_at > now()));
create policy notices_admin_all on public.notices
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- 원격 설정: 누구나 읽기, 관리자만 수정
create policy app_config_public_read on public.app_config
  for select to anon, authenticated using (true);
create policy app_config_admin_all on public.app_config
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- 제보·이벤트: 누구나 추가만, 관리자만 조회·수정
create policy feedback_insert on public.feedback
  for insert to anon, authenticated with check (status = 'new' and admin_note is null);
create policy feedback_admin_all on public.feedback
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy events_insert on public.events
  for insert to anon, authenticated with check (true);
create policy events_admin_read on public.events
  for select to authenticated using (public.is_admin());

-- ---------------------------------------------------------------------------
-- 대시보드용 일별 집계 (관리자만 — security_invoker 로 RLS 그대로 적용)
-- ---------------------------------------------------------------------------
create view public.daily_stats with (security_invoker = true) as
select
  app,
  (occurred_at at time zone 'Asia/Seoul')::date as day,
  count(*) filter (where name = 'trip_started') as trips,
  count(*) filter (where name = 'alert_fired') as alerts,
  count(*) filter (where name = 'trip_ended' and props->>'mode' = 'realtime') as realtime_trips,
  count(*) filter (where name = 'trip_ended' and props->>'mode' = 'fallback') as fallback_trips,
  coalesce(sum((props->>'api_calls')::int) filter (where name = 'trip_ended'), 0) as api_calls,
  count(distinct device_id) as devices
from public.events
group by app, day;

-- ---------------------------------------------------------------------------
-- 첫 관리자 등록 (Supabase 대시보드 > Authentication 에서 계정 만든 뒤 실행)
--   insert into public.admins (user_id)
--   select id from auth.users where email = 'YOUR_EMAIL';
-- ---------------------------------------------------------------------------
