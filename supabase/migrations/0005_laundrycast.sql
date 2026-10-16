-- 0005 — 런디캐스트(laundrycast) 백엔드 스키마.
--
-- 같은 kwakkit 프로젝트를 쓰므로 표 이름에 lc_ 접두어(devices·loads 같은 이름 충돌 방지).
-- 마이그레이션은 이 저장소에서만 관리한다(원격 이력이 하나여야 supabase db push 가 동작).
-- 수집·발송 코드(Edge Function)는 laundrycast 저장소 supabase/functions/.
--
-- 원칙 (laundrycast CLAUDE.md "핵심 제약")
--   - 앱은 익명 로그인(authenticated). 자기 기기·빨래 행만 읽고 쓴다.
--   - 정확 위치는 없다 — 기상청 격자(nx·ny)와 미세먼지 권역(예: '서울', '경기북부')만.
--   - 날씨 API 호출·푸시 발송은 Edge Function(service_role)만. 앱은 예보를 읽기만.
--   - 시간: 모두 timestamptz(UTC). 격자별 tz 로 현지 시각을 계산한다.

-- ---------------------------------------------------------------------------
-- 날씨 격자 — 활성 사용자가 있는 칸만 수집(API 비용 = 칸 수)
-- ---------------------------------------------------------------------------
create table public.lc_grid_cells (
  id bigint generated always as identity primary key,
  provider text not null check (provider in ('kma')),
  nx int not null check (nx between 1 and 149),
  ny int not null check (ny between 1 and 253),
  tz text not null default 'Asia/Seoul',
  created_at timestamptz not null default now(),
  last_fetched_at timestamptz,
  unique (provider, nx, ny)
);

-- 시간별 예보. ts = 그 시간의 **시작** — [ts, ts+1h] 구간 값(ET0 는 그 1시간 합).
create table public.lc_forecast_hourly (
  cell_id bigint not null references public.lc_grid_cells on delete cascade,
  ts timestamptz not null,
  temp real,
  rh smallint,
  wind real,
  sky smallint,          -- 기상청 SKY 1 맑음 / 3 구름많음 / 4 흐림
  pty smallint,          -- 기상청 PTY 0 없음 / 1 비 / 2 비·눈 / 3 눈 / 4 소나기
  pop smallint,          -- 강수확률 %
  pcp_mm real,
  et0 real not null,     -- mm/h, FAO-56 (하늘상태로 일사 추정 — VALIDATION.md §2)
  base_time timestamptz not null,
  primary key (cell_id, ts)
);

-- 미세먼지 예보(에어코리아) — 권역·날짜별 PM10·PM2.5 중 나쁜 쪽.
create table public.lc_dust_daily (
  region text not null,
  day date not null,
  grade text not null check (grade in ('good', 'moderate', 'bad', 'very_bad')),
  issued_at timestamptz not null,
  primary key (region, day)
);

-- 건조 모델 파라미터 — 앱의 ModelParams. v1 피드백 보정으로 갱신.
create table public.lc_model_params (
  scope text primary key,
  params jsonb not null,
  fitted_at timestamptz,
  n_samples int not null default 0,
  updated_at timestamptz not null default now()
);

insert into public.lc_model_params (scope, params) values ('kr', '{
  "place_factor": {"outdoor": 1.0, "balcony": 0.5, "indoor": 0.2},
  "theta": {"thin": 0.6, "normal": 1.0, "thick": 1.6},
  "rain_prob_threshold": 50,
  "day_end_hour": 21,
  "earliest_hang_hour": 6,
  "latest_hang_hour": 18
}');

-- ---------------------------------------------------------------------------
-- 기기 · 빨래 · 피드백 (본인 행만)
-- ---------------------------------------------------------------------------
create table public.lc_devices (
  id uuid primary key default auth.uid() references auth.users on delete cascade,
  cell_id bigint references public.lc_grid_cells on delete set null,
  dust_region text,
  fcm_token text check (char_length(fcm_token) <= 4096),
  locale text not null default 'ko' check (char_length(locale) <= 16),
  alert_minutes smallint not null default 450 check (alert_minutes between 0 and 1439),
  morning_alert boolean not null default true,
  rain_alert boolean not null default true,
  dry_alert boolean not null default true,
  place text not null default 'balcony' check (place in ('outdoor', 'balcony', 'indoor')),
  fabric text not null default 'normal' check (fabric in ('thin', 'normal', 'thick')),
  app_version text check (char_length(app_version) <= 32),
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.lc_loads (
  id bigint generated always as identity primary key,
  device_id uuid not null default auth.uid() references public.lc_devices on delete cascade,
  cell_id bigint references public.lc_grid_cells on delete set null,
  hung_at timestamptz not null,
  place text not null check (place in ('outdoor', 'balcony', 'indoor')),
  fabric text not null check (fabric in ('thin', 'normal', 'thick')),
  predicted_dry_at timestamptz,
  ended_at timestamptz,
  canceled boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.lc_load_feedback (
  load_id bigint primary key references public.lc_loads on delete cascade,
  result text not null check (result in ('dry', 'damp')),
  actual_dry_at timestamptz,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 운영 로그 (관리자만 읽음, service_role 이 씀) — 콘솔 패널 "격자·API" · "푸시"
-- ---------------------------------------------------------------------------
create table public.lc_fetch_log (
  id bigint generated always as identity primary key,
  provider text not null,
  kind text not null,
  cell_id bigint,
  ok boolean not null,
  status text,
  rows int not null default 0,
  created_at timestamptz not null default now()
);

-- dedupe_key 로 같은 알림을 두 번 보내지 않는다('morning:2026-10-16', 'rain:<load_id>', 'dry:<load_id>').
create table public.lc_push_log (
  id bigint generated always as identity primary key,
  device_id uuid not null references public.lc_devices on delete cascade,
  kind text not null check (kind in ('morning', 'rain', 'eta_change', 'dry')),
  dedupe_key text not null,
  ok boolean,
  error text,
  created_at timestamptz not null default now(),
  unique (device_id, dedupe_key)
);

create index lc_forecast_hourly_ts_idx on public.lc_forecast_hourly (ts);
create index lc_devices_cell_idx on public.lc_devices (cell_id);
create index lc_loads_device_idx on public.lc_loads (device_id, hung_at desc);
create index lc_loads_open_idx on public.lc_loads (hung_at) where ended_at is null and not canceled;
create index lc_fetch_log_created_idx on public.lc_fetch_log (created_at);
create index lc_push_log_created_idx on public.lc_push_log (created_at);

create trigger lc_devices_touch before update on public.lc_devices
  for each row execute function public.touch_updated_at();
create trigger lc_model_params_touch before update on public.lc_model_params
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.lc_grid_cells enable row level security;
alter table public.lc_forecast_hourly enable row level security;
alter table public.lc_dust_daily enable row level security;
alter table public.lc_model_params enable row level security;
alter table public.lc_devices enable row level security;
alter table public.lc_loads enable row level security;
alter table public.lc_load_feedback enable row level security;
alter table public.lc_fetch_log enable row level security;
alter table public.lc_push_log enable row level security;

-- 내 기기의 격자 — 활성 격자 목록 전체를 남이 훑지 못하게.
create or replace function public.lc_my_cell()
returns bigint
language sql stable security definer set search_path = public
as $$
  select cell_id from public.lc_devices where id = auth.uid();
$$;

create policy lc_grid_cells_read on public.lc_grid_cells
  for select to authenticated using (id = public.lc_my_cell() or public.is_admin());

create policy lc_forecast_read on public.lc_forecast_hourly
  for select to authenticated using (cell_id = public.lc_my_cell() or public.is_admin());

create policy lc_dust_read on public.lc_dust_daily
  for select to authenticated using (true);

create policy lc_model_params_read on public.lc_model_params
  for select to anon, authenticated using (true);
create policy lc_model_params_admin on public.lc_model_params
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- 기기: 본인 행만. 격자 등록은 lc_register_device() 로(격자 표는 직접 못 씀).
create policy lc_devices_own on public.lc_devices
  for all to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy lc_devices_admin_read on public.lc_devices
  for select to authenticated using (public.is_admin());

-- 빨래: 본인 것만. 널은 시각은 최근 3일 ~ 지금+10분(오프라인 뒤 늦게 올리는 경우 허용).
create policy lc_loads_own_read on public.lc_loads
  for select to authenticated using (device_id = auth.uid() or public.is_admin());
create policy lc_loads_own_insert on public.lc_loads
  for insert to authenticated with check (
    device_id = auth.uid()
    and hung_at between now() - interval '3 days' and now() + interval '10 minutes'
  );
create policy lc_loads_own_update on public.lc_loads
  for update to authenticated using (device_id = auth.uid()) with check (device_id = auth.uid());
create policy lc_loads_own_delete on public.lc_loads
  for delete to authenticated using (device_id = auth.uid());

create policy lc_load_feedback_own_read on public.lc_load_feedback
  for select to authenticated using (
    public.is_admin()
    or exists (select 1 from public.lc_loads l where l.id = load_id and l.device_id = auth.uid())
  );
create policy lc_load_feedback_own_insert on public.lc_load_feedback
  for insert to authenticated with check (
    exists (select 1 from public.lc_loads l where l.id = load_id and l.device_id = auth.uid())
  );

create policy lc_fetch_log_admin_read on public.lc_fetch_log
  for select to authenticated using (public.is_admin());
create policy lc_push_log_admin_read on public.lc_push_log
  for select to authenticated using (public.is_admin());

-- ---------------------------------------------------------------------------
-- RPC (앱)
-- ---------------------------------------------------------------------------

-- 기기 등록·갱신 + 격자 등록. 지역을 바꿀 때도 이것만 부른다. 반환 = 격자 id.
create or replace function public.lc_register_device(
  p_nx int,
  p_ny int,
  p_dust_region text default null,
  p_locale text default 'ko',
  p_app_version text default null
)
returns bigint
language plpgsql security definer set search_path = public
as $$
declare
  v_cell bigint;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  if p_nx not between 1 and 149 or p_ny not between 1 and 253 then
    raise exception 'grid out of range';
  end if;

  insert into public.lc_grid_cells (provider, nx, ny)
  values ('kma', p_nx, p_ny)
  on conflict (provider, nx, ny) do update set nx = excluded.nx
  returning id into v_cell;

  insert into public.lc_devices (id, cell_id, dust_region, locale, app_version, last_seen_at)
  values (auth.uid(), v_cell, left(p_dust_region, 16), left(coalesce(p_locale, 'ko'), 16),
          left(p_app_version, 32), now())
  on conflict (id) do update set
    cell_id = excluded.cell_id,
    dust_region = excluded.dust_region,
    locale = excluded.locale,
    app_version = excluded.app_version,
    last_seen_at = now();

  return v_cell;
end;
$$;

-- 내 기록 삭제 — 익명 계정째 지운다(기기·빨래·피드백·푸시 기록은 FK cascade).
create or replace function public.lc_delete_me()
returns void
language plpgsql security definer set search_path = public, auth
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.lc_register_device(int, int, text, text, text) from public, anon;
grant execute on function public.lc_register_device(int, int, text, text, text) to authenticated;
revoke all on function public.lc_delete_me() from public, anon;
grant execute on function public.lc_delete_me() to authenticated;

-- ---------------------------------------------------------------------------
-- 수집·발송용 (Edge Function = service_role 만)
-- ---------------------------------------------------------------------------

-- 수집 대상: 최근 30일 안에 앱을 연 기기가 있는 격자.
create view public.lc_active_cells with (security_invoker = true) as
select c.*
from public.lc_grid_cells c
where exists (
  select 1 from public.lc_devices d
  where d.cell_id = c.id and d.last_seen_at > now() - interval '30 days'
);

-- 아침 알림 대상: 지금(격자 현지 시각)이 알림 시각부터 p_window 분 안이고, 오늘 아직 안 보낸 기기.
create or replace function public.lc_morning_targets(p_window int default 10)
returns table (
  device_id uuid, fcm_token text, cell_id bigint, tz text, locale text,
  place text, fabric text, local_day date
)
language sql stable security definer set search_path = public
as $$
  select d.id, d.fcm_token, d.cell_id, c.tz, d.locale, d.place, d.fabric,
         (now() at time zone c.tz)::date
  from public.lc_devices d
  join public.lc_grid_cells c on c.id = d.cell_id
  where d.morning_alert
    and d.fcm_token is not null
    and ((extract(hour from now() at time zone c.tz)::int * 60
          + extract(minute from now() at time zone c.tz)::int
          - d.alert_minutes + 1440) % 1440) < p_window
    and not exists (
      select 1 from public.lc_push_log p
      where p.device_id = d.id
        and p.dedupe_key = 'morning:' || (now() at time zone c.tz)::date
    );
$$;

revoke all on function public.lc_morning_targets(int) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 콘솔 패널용 집계 (관리자만 — security_invoker 로 RLS 적용)
-- ---------------------------------------------------------------------------

-- 예측 정확도: 예측 대비 실제 마름 시각 오차(분). 글로벌 관문 지표(DESIGN.md §9).
create view public.lc_accuracy with (security_invoker = true) as
select
  l.place,
  l.fabric,
  count(*) as feedbacks,
  count(*) filter (where f.result = 'dry' and f.actual_dry_at is not null
                   and l.predicted_dry_at is not null) as timed,
  percentile_cont(0.5) within group (
    order by abs(extract(epoch from (f.actual_dry_at - l.predicted_dry_at)) / 60)
  ) filter (where f.actual_dry_at is not null and l.predicted_dry_at is not null) as median_abs_err_min,
  avg(abs(extract(epoch from (f.actual_dry_at - l.predicted_dry_at)) / 60))
    filter (where f.actual_dry_at is not null and l.predicted_dry_at is not null) as mae_min
from public.lc_loads l
join public.lc_load_feedback f on f.load_id = l.id
group by l.place, l.fabric;

-- 일별 날씨 API 호출 수(Asia/Seoul) — 한도 대비.
create view public.lc_fetch_daily with (security_invoker = true) as
select provider, kind, (created_at at time zone 'Asia/Seoul')::date as day,
       count(*) as calls, count(*) filter (where not ok) as failures
from public.lc_fetch_log
group by provider, kind, day;
