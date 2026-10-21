-- 0017 — 런디캐스트 전용 콘솔(laundrycast-console 저장소, React + Supabase)용 스키마.
--
-- 하차각 콘솔과 표·관리자를 공유하지 않는다:
--   - 관리자: lc_admins + lc_is_admin(). 런디캐스트 표(lc_*)의 관리자 정책도 is_admin()(하차각) → lc_is_admin().
--   - 운영 표: lc_notices(공지) · lc_app_config(원격 설정) · lc_feedback(제보) · lc_events(사용 이벤트).
--     앱(익명 로그인 = authenticated, 로그인 전 anon)은 공지·설정 읽기만, 제보·이벤트 쓰기만.
--   - 대시보드: lc_console_overview() 한 번으로 집계만 받는다(관리자만, 원본 행은 콘솔로 안 나간다).
-- 위치는 여기에도 없다 — 기기 지역은 미세먼지 권역(시·도 수준) 집계뿐, 제보·이벤트의 device_id 는 앱이 만든 랜덤 UUID
-- (lc_devices.id 와 다른 값).
-- 쓰기 검증 위반은 오류 대신 조용히 버린다(배치 하나가 400 이 되면 기기 대기열 전체가 막히는 "독 배치" 방지, 0003 참고).

-- ---------------------------------------------------------------------------
-- 1. 관리자
-- ---------------------------------------------------------------------------

create table public.lc_admins (
  user_id uuid primary key references auth.users on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.lc_admins enable row level security;
create policy lc_admins_self_read on public.lc_admins
  for select to authenticated using (user_id = (select auth.uid()));

create or replace function public.lc_is_admin()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from public.lc_admins where user_id = auth.uid());
$$;
revoke all on function public.lc_is_admin() from public, anon;
grant execute on function public.lc_is_admin() to authenticated;

-- 기존 lc_* 관리자 정책을 런디캐스트 관리자로.
drop policy lc_devices_admin_read on public.lc_devices;
create policy lc_devices_admin_read on public.lc_devices
  for select to authenticated using (public.lc_is_admin());

drop policy lc_fetch_log_admin_read on public.lc_fetch_log;
create policy lc_fetch_log_admin_read on public.lc_fetch_log
  for select to authenticated using (public.lc_is_admin());

drop policy lc_push_log_admin_read on public.lc_push_log;
create policy lc_push_log_admin_read on public.lc_push_log
  for select to authenticated using (public.lc_is_admin());

drop policy lc_forecast_read on public.lc_forecast_hourly;
create policy lc_forecast_read on public.lc_forecast_hourly
  for select to authenticated using (cell_id = public.lc_my_cell() or public.lc_is_admin());

drop policy lc_grid_cells_read on public.lc_grid_cells;
create policy lc_grid_cells_read on public.lc_grid_cells
  for select to authenticated using (id = public.lc_my_cell() or public.lc_is_admin());

drop policy lc_loads_own_read on public.lc_loads;
create policy lc_loads_own_read on public.lc_loads
  for select to authenticated using (device_id = (select auth.uid()) or public.lc_is_admin());

drop policy lc_load_feedback_own_read on public.lc_load_feedback;
create policy lc_load_feedback_own_read on public.lc_load_feedback
  for select to authenticated using (
    public.lc_is_admin()
    or exists (select 1 from public.lc_loads l where l.id = load_id and l.device_id = (select auth.uid()))
  );

drop policy lc_model_params_admin on public.lc_model_params;
create policy lc_model_params_admin on public.lc_model_params
  for all to authenticated using (public.lc_is_admin()) with check (public.lc_is_admin());

-- ---------------------------------------------------------------------------
-- 2. 공지 · 원격 설정 (앱이 읽음)
-- ---------------------------------------------------------------------------

create table public.lc_notices (
  id bigint generated always as identity primary key,
  title text not null check (char_length(title) between 1 and 100),
  body text not null check (char_length(body) between 1 and 2000),
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at is null or ends_at > starts_at)
);
create index lc_notices_starts_idx on public.lc_notices (starts_at desc);

create table public.lc_app_config (
  key text primary key check (key ~ '^[a-z][a-z0-9_]{0,63}$'),
  value jsonb not null,
  description text,
  updated_at timestamptz not null default now()
);

insert into public.lc_app_config (key, value, description) values
  ('min_version', '"1.0.0"', '이보다 낮으면 강제 업데이트 — 스토어 페이지가 생기기 전엔 올리지 말 것'),
  ('latest_version', '"1.0.0"', '이보다 낮으면 업데이트 권장');

create trigger lc_notices_touch before update on public.lc_notices
  for each row execute function public.touch_updated_at();
create trigger lc_app_config_touch before update on public.lc_app_config
  for each row execute function public.touch_updated_at();

alter table public.lc_notices enable row level security;
alter table public.lc_app_config enable row level security;

create policy lc_notices_public_read on public.lc_notices
  for select to anon, authenticated
  using (starts_at <= now() and (ends_at is null or ends_at > now()));
create policy lc_notices_admin_all on public.lc_notices
  for all to authenticated using (public.lc_is_admin()) with check (public.lc_is_admin());

create policy lc_app_config_public_read on public.lc_app_config
  for select to anon, authenticated using (true);
-- 키 추가·삭제는 마이그레이션으로만 — 콘솔은 값만 고친다.
create policy lc_app_config_admin_update on public.lc_app_config
  for update to authenticated using (public.lc_is_admin()) with check (public.lc_is_admin());

-- ---------------------------------------------------------------------------
-- 3. 제보 · 이벤트 (앱이 쓰기만)
-- ---------------------------------------------------------------------------

create table public.lc_feedback (
  id bigint generated always as identity primary key,
  device_id uuid,
  app_version text,
  os text,
  category text not null default 'bug' check (category in ('bug', 'idea', 'etc')),
  message text not null check (char_length(message) between 1 and 2000),
  status text not null default 'new' check (status in ('new', 'checking', 'done')),
  admin_note text,
  created_at timestamptz not null default now()
);
create index lc_feedback_status_idx on public.lc_feedback (status, created_at desc);
create index lc_feedback_device_idx on public.lc_feedback (device_id, created_at);

-- 이름 검증은 CHECK 가 아니라 가드에서(조용히 버림). DB 에 이미 있는 널기·피드백은 이벤트로 받지 않는다.
create table public.lc_events (
  id bigint generated always as identity primary key,
  device_id uuid,
  app_version text,
  name text not null,
  props jsonb not null default '{}',
  occurred_at timestamptz not null,
  created_at timestamptz not null default now()
);
create index lc_events_occurred_idx on public.lc_events (occurred_at);
create index lc_events_device_idx on public.lc_events (device_id, created_at);
create index lc_events_created_idx on public.lc_events (created_at);

alter table public.lc_feedback enable row level security;
alter table public.lc_events enable row level security;

create policy lc_feedback_insert on public.lc_feedback
  for insert to anon, authenticated with check (status = 'new' and admin_note is null);
create policy lc_feedback_admin_read on public.lc_feedback
  for select to authenticated using (public.lc_is_admin());
create policy lc_feedback_admin_update on public.lc_feedback
  for update to authenticated using (public.lc_is_admin()) with check (public.lc_is_admin());
create policy lc_feedback_admin_delete on public.lc_feedback
  for delete to authenticated using (public.lc_is_admin());

create policy lc_events_insert on public.lc_events
  for insert to anon, authenticated with check (true);
create policy lc_events_admin_read on public.lc_events
  for select to authenticated using (public.lc_is_admin());

-- 제보 1행: 기기당 하루 10건(기기 id 없는 건 묶어서 30건), 메타데이터는 자른다(사용자 글은 버리지 않게).
create or replace function public.lc_guard_feedback_insert()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  recent int;
  daily_cap int := case when new.device_id is null then 30 else 10 end;
begin
  select count(*) into recent from (
    select 1 from public.lc_feedback
    where device_id is not distinct from new.device_id
      and created_at > now() - interval '1 day'
    limit 30
  ) s;
  if recent >= daily_cap then
    return null;
  end if;
  new.app_version := left(new.app_version, 32);
  new.os := left(new.os, 64);
  new.status := 'new';
  new.admin_note := null;
  new.created_at := now();
  return new;
end;
$$;

create trigger lc_feedback_guard before insert on public.lc_feedback
  for each row execute function public.lc_guard_feedback_insert();

-- 이벤트 1행: 아는 이름만, props 512바이트 이하, 시각은 30일 전 ~ 1시간 뒤, 기기당 시간당 300건.
create or replace function public.lc_guard_event_insert()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  recent int;
begin
  if new.name not in ('onboarding_done', 'push_opened', 'notification_permission')
     or jsonb_typeof(new.props) is distinct from 'object'
     or pg_column_size(new.props) > 512
     or new.occurred_at is null
     or new.occurred_at > now() + interval '1 hour'
     or new.occurred_at < now() - interval '30 days'
     or char_length(coalesce(new.app_version, '')) > 32 then
    return null;
  end if;

  select count(*) into recent from (
    select 1 from public.lc_events
    where device_id is not distinct from new.device_id
      and created_at > now() - interval '1 hour'
    limit 300
  ) s;
  if recent >= 300 then
    return null;
  end if;

  new.created_at := now();
  return new;
end;
$$;

create trigger lc_events_guard before insert on public.lc_events
  for each row execute function public.lc_guard_event_insert();

revoke all on function public.lc_guard_feedback_insert() from public, anon, authenticated;
revoke all on function public.lc_guard_event_insert() from public, anon, authenticated;

-- 원본 이벤트는 90일만.
create or replace function public.lc_purge_old_events()
returns integer
language plpgsql security definer set search_path = public
as $$
declare
  n int;
begin
  delete from public.lc_events where created_at < now() - interval '90 days';
  get diagnostics n = row_count;
  return n;
end;
$$;
revoke all on function public.lc_purge_old_events() from public, anon, authenticated;

select cron.schedule('laundrycast-purge-old-events', '40 18 * * *',  -- 매일 03:40 KST
  'select public.lc_purge_old_events()');

-- ---------------------------------------------------------------------------
-- 4. 대시보드 집계 (관리자만)
-- ---------------------------------------------------------------------------
-- 하루 경계는 Asia/Seoul(한국 단계). 글로벌 단계에서 국가별 현지 일자로 확장.

create or replace function public.lc_console_overview(p_days int default 14)
returns jsonb
language plpgsql stable security definer set search_path = public
as $$
declare
  v_days int := least(greatest(coalesce(p_days, 14), 1), 90);
  v_since timestamptz := now() - make_interval(days => v_days);
  v_today_start timestamptz := (date_trunc('day', now() at time zone 'Asia/Seoul')) at time zone 'Asia/Seoul';
  v_30 timestamptz := now() - interval '30 days';
begin
  if not public.lc_is_admin() then
    raise exception 'admin only' using errcode = '42501';
  end if;

  return jsonb_build_object(
    'generated_at', now(),
    'days', v_days,
    'devices', (
      select jsonb_build_object(
        'total', count(*),
        'active_7d', count(*) filter (where last_seen_at > now() - interval '7 days'),
        'active_30d', count(*) filter (where last_seen_at > v_30),
        'push_ready', count(*) filter (where fcm_token is not null and last_seen_at > v_30),
        'new_7d', count(*) filter (where created_at > now() - interval '7 days'))
      from public.lc_devices),
    'devices_by_region', coalesce((
      select jsonb_agg(jsonb_build_object('region', region, 'devices', n) order by n desc, region)
      from (select coalesce(dust_region, '기타') as region, count(*) as n
            from public.lc_devices where last_seen_at > v_30 group by 1) s), '[]'::jsonb),
    'devices_by_locale', coalesce((
      select jsonb_agg(jsonb_build_object('locale', locale, 'devices', n) order by n desc, locale)
      from (select locale, count(*) as n
            from public.lc_devices where last_seen_at > v_30 group by 1) s), '[]'::jsonb),
    'cells', jsonb_build_object(
      'active', (select count(*) from public.lc_active_cells),
      'total', (select count(*) from public.lc_grid_cells)),
    'kma_calls_today', (
      select count(*) from public.lc_fetch_log
      where provider = 'kma' and created_at >= v_today_start),
    'kma_daily_cap', 9000,
    'fetch_daily', coalesce((
      select jsonb_agg(jsonb_build_object(
               'day', day, 'provider', provider, 'kind', kind, 'calls', calls, 'failures', failures)
             order by day desc, provider, kind)
      from (select (created_at at time zone 'Asia/Seoul')::date as day, provider, kind,
                   count(*) as calls, count(*) filter (where not ok) as failures
            from public.lc_fetch_log where created_at > v_since group by 1, 2, 3) s), '[]'::jsonb),
    'push_daily', coalesce((
      select jsonb_agg(jsonb_build_object(
               'day', day, 'kind', kind, 'sent', sent, 'failed', failed, 'pending', pending)
             order by day desc, kind)
      from (select (created_at at time zone 'Asia/Seoul')::date as day, kind,
                   count(*) filter (where ok) as sent,
                   count(*) filter (where ok = false) as failed,
                   count(*) filter (where ok is null) as pending
            from public.lc_push_log where created_at > v_since group by 1, 2) s), '[]'::jsonb),
    'loads_30d', (
      select jsonb_build_object(
        'hung', count(*),
        'ended', count(*) filter (where ended_at is not null and not canceled),
        'canceled', count(*) filter (where canceled),
        'feedbacks', count(f.load_id),
        'feedbacks_timed', count(f.load_id) filter (where f.result = 'dry' and f.actual_dry_at is not null))
      from public.lc_loads l
      left join public.lc_load_feedback f on f.load_id = l.id
      where l.hung_at > v_30),
    'accuracy', coalesce((
      select jsonb_agg(to_jsonb(a) order by a.place, a.fabric) from public.lc_accuracy a), '[]'::jsonb),
    'events_daily', coalesce((
      select jsonb_agg(jsonb_build_object('day', day, 'name', name, 'events', n, 'devices', d)
             order by day desc, name)
      from (select (occurred_at at time zone 'Asia/Seoul')::date as day, name,
                   count(*) as n, count(distinct device_id) as d
            from public.lc_events where occurred_at > v_since group by 1, 2) s), '[]'::jsonb),
    'feedback_new', (select count(*) from public.lc_feedback where status = 'new')
  );
end;
$$;

revoke all on function public.lc_console_overview(int) from public, anon;
grant execute on function public.lc_console_overview(int) to authenticated;
