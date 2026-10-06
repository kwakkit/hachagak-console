-- 0003 — 사용자 증가 대비.
--   1) 앱(anon) 쓰기 남용 방어: events·feedback 입력 검증 + 기기당 횟수 제한.
--   2) daily_stats 를 뷰 → 집계 테이블로. 대시보드가 events 전체를 매번 다시 세지 않는다.
--   3) 원본 events 는 90일만 보관 (집계는 영구).
--
-- 검증 위반 행은 오류 대신 **조용히 버린다**(BEFORE INSERT 트리거가 null 반환).
-- 하차각은 이벤트를 100건씩 일괄 POST 하는데, 한 행이라도 CHECK 위반으로 400 이 나면
-- 배치 전체가 기기 큐에 남아 매 실행마다 재전송되는 "독 배치"가 되기 때문.

-- ---------------------------------------------------------------------------
-- 1. 쓰기 남용 방어
-- ---------------------------------------------------------------------------

create index if not exists events_device_created_idx on public.events (device_id, created_at);
create index if not exists events_created_idx on public.events (created_at);
create index if not exists feedback_device_created_idx on public.feedback (device_id, created_at);

-- 이벤트 1행 검증. 앱 큐 상한(300건)을 한 번에 비울 수 있게 기기당 시간당 300건.
-- 같은 INSERT 문에서 앞서 처리된 행도 BEFORE 트리거의 조회에 보이므로 배치 안에서도 센다.
-- security definer — anon 은 events 를 읽을 수 없어(RLS) 횟수를 세려면 필요.
create or replace function public.guard_event_insert()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  recent int;
begin
  if new.app is distinct from 'hachagak'
     or new.name not in ('trip_started', 'alert_fired', 'trip_ended')
     or jsonb_typeof(new.props) is distinct from 'object'
     or pg_column_size(new.props) > 512
     or new.occurred_at is null
     or new.occurred_at > now() + interval '1 hour'
     or new.occurred_at < now() - interval '30 days'
     or char_length(coalesce(new.app_version, '')) > 32 then
    return null;
  end if;

  select count(*) into recent from (
    select 1 from public.events
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

create trigger events_guard before insert on public.events
  for each row execute function public.guard_event_insert();

-- 제보 1행 검증. 기기당 하루 10건 (기기 UUID 가 없는 제보는 한 묶음으로 하루 30건).
-- 짧은 메타데이터는 버리지 않고 자른다 — 사용자가 쓴 제보를 잃지 않게.
create or replace function public.guard_feedback_insert()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  recent int;
  daily_cap int := case when new.device_id is null then 30 else 10 end;
begin
  if new.app is distinct from 'hachagak' then
    return null;
  end if;

  select count(*) into recent from (
    select 1 from public.feedback
    where device_id is not distinct from new.device_id
      and created_at > now() - interval '1 day'
    limit 30
  ) s;
  if recent >= daily_cap then
    return null;
  end if;

  new.app_version := left(new.app_version, 32);
  new.os := left(new.os, 64);
  new.created_at := now();
  return new;
end;
$$;

create trigger feedback_guard before insert on public.feedback
  for each row execute function public.guard_feedback_insert();

-- ---------------------------------------------------------------------------
-- 2. 일별 집계 테이블
-- ---------------------------------------------------------------------------

drop view if exists public.daily_stats;

-- 열 이름·의미는 0002 의 뷰와 같다 (콘솔 DailyStat 그대로).
create table public.daily_stats (
  app text not null,
  day date not null,
  trips int not null default 0,
  alerts int not null default 0,
  realtime_trips int not null default 0,
  fallback_trips int not null default 0,
  api_calls bigint not null default 0,
  devices int not null default 0,
  timetable_trips int not null default 0,
  ended_trips int not null default 0,
  arrived_trips int not null default 0,
  refreshed_at timestamptz not null default now(),
  primary key (app, day)
);

alter table public.daily_stats enable row level security;
create policy daily_stats_admin_read on public.daily_stats
  for select to authenticated using (public.is_admin());

-- 마지막 갱신 시각 (행 1개). 정책 없음 = 함수(definer)만 접근.
create table public.stats_refresh_state (
  id boolean primary key default true check (id),
  refreshed_at timestamptz not null
);
insert into public.stats_refresh_state (refreshed_at) values ('-infinity');
alter table public.stats_refresh_state enable row level security;

-- 지난 갱신 이후 새로 들어온 이벤트가 걸친 날만 통째로 다시 센다. 앱은 다음 실행 때
-- 몰아 보내므로 며칠 전 날짜도 바뀔 수 있다 — 그래서 occurred_at 이 아니라
-- created_at 으로 "바뀐 날"을 찾는다. 10분 겹침은 갱신 직전에 시작해 늦게 커밋된
-- 트랜잭션 몫. 반환값: 다시 센 날 수 (다른 갱신이 도는 중이면 0).
-- 호출: pg_cron(매시) · 콘솔 대시보드(관리자). anon 은 실행 권한 없음.
create or replace function public.refresh_daily_stats()
returns integer
language plpgsql security definer set search_path = public
as $$
declare
  since timestamptz;
  started timestamptz := now();
  n int;
begin
  if coalesce(auth.role(), '') in ('anon', 'authenticated') and not public.is_admin() then
    raise exception 'admin only' using errcode = '42501';
  end if;
  if not pg_try_advisory_xact_lock(hashtext('public.refresh_daily_stats')) then
    return 0;
  end if;

  select refreshed_at into since from public.stats_refresh_state for update;

  with touched as (
    select distinct app, (occurred_at at time zone 'Asia/Seoul')::date as day
    from public.events
    where created_at >= since - interval '10 minutes'
  ), agg as (
    select
      t.app,
      t.day,
      count(*) filter (where e.name = 'trip_started') as trips,
      count(*) filter (where e.name = 'alert_fired') as alerts,
      count(*) filter (where e.name = 'trip_ended' and e.props->>'mode' = 'realtime') as realtime_trips,
      count(*) filter (where e.name = 'trip_ended' and e.props->>'mode' = 'fallback') as fallback_trips,
      coalesce(sum((e.props->>'api_calls')::int) filter (
        where e.name = 'trip_ended' and e.props->>'api_calls' ~ '^\d{1,9}$'), 0) as api_calls,
      count(distinct e.device_id) as devices,
      count(*) filter (where e.name = 'trip_ended' and e.props->>'mode' = 'timetable') as timetable_trips,
      count(*) filter (where e.name = 'trip_ended') as ended_trips,
      count(*) filter (where e.name = 'trip_ended' and e.props->>'reason' = 'arrived') as arrived_trips
    from touched t
    join public.events e
      on e.app = t.app
     and e.occurred_at >= (t.day::timestamp at time zone 'Asia/Seoul')
     and e.occurred_at < ((t.day + 1)::timestamp at time zone 'Asia/Seoul')
    group by t.app, t.day
  )
  insert into public.daily_stats as d (
    app, day, trips, alerts, realtime_trips, fallback_trips, api_calls, devices,
    timetable_trips, ended_trips, arrived_trips, refreshed_at)
  select
    app, day, trips, alerts, realtime_trips, fallback_trips, api_calls, devices,
    timetable_trips, ended_trips, arrived_trips, started
  from agg
  on conflict (app, day) do update set
    trips = excluded.trips,
    alerts = excluded.alerts,
    realtime_trips = excluded.realtime_trips,
    fallback_trips = excluded.fallback_trips,
    api_calls = excluded.api_calls,
    devices = excluded.devices,
    timetable_trips = excluded.timetable_trips,
    ended_trips = excluded.ended_trips,
    arrived_trips = excluded.arrived_trips,
    refreshed_at = excluded.refreshed_at;
  get diagnostics n = row_count;

  update public.stats_refresh_state set refreshed_at = started;
  return n;
end;
$$;

revoke all on function public.refresh_daily_stats() from public, anon;
grant execute on function public.refresh_daily_stats() to authenticated;

-- ---------------------------------------------------------------------------
-- 3. 원본 이벤트 보관 기간 — 90일. 트리거가 30일보다 오래된 occurred_at 을 버리므로
--    지워진 날짜를 refresh 가 다시 셀 일은 없다(집계가 줄어들지 않음).
-- ---------------------------------------------------------------------------

create or replace function public.purge_old_events()
returns integer
language plpgsql security definer set search_path = public
as $$
declare
  n int;
begin
  delete from public.events where created_at < now() - interval '90 days';
  get diagnostics n = row_count;
  return n;
end;
$$;

revoke all on function public.purge_old_events() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 4. 스케줄 (pg_cron, UTC) — 같은 이름이면 덮어쓴다.
-- ---------------------------------------------------------------------------

create extension if not exists pg_cron;

select cron.schedule('hachagak-refresh-daily-stats', '5 * * * *',
  'select public.refresh_daily_stats()');
select cron.schedule('hachagak-purge-old-events', '30 18 * * *',  -- 매일 03:30 KST
  'select public.purge_old_events()');

-- 기존 이벤트로 첫 집계.
select public.refresh_daily_stats();
