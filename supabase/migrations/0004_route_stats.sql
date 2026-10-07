-- 0004 — 경로 통계 (노선 단위). 0003 위에 쌓는다.
--
-- 하차각 0.3.x 부터 trip_started.props = {lines: ["2","3"], transfers: 1, stops: 9}.
-- **역 이름·출발/도착·위치는 받지 않는다** — Play 데이터 보안 양식 "앱 활동(앱 상호작용)" 범위.
-- 이 정보가 없는 옛 앱의 trip_started 는 route_trips 에서 빠진다(평균의 분모도 route_trips).

alter table public.daily_stats
  add column route_trips int not null default 0,     -- 노선 정보가 있는 trip_started 수
  add column transfer_trips int not null default 0,  -- 그중 환승이 1회 이상
  add column transfers_sum int not null default 0,   -- 환승 횟수 합
  add column stops_sum int not null default 0;       -- 정거장 수 합

-- 노선별 하루 이용 여정 수. 한 여정이 같은 노선을 두 번 타도 1.
create table public.daily_line_stats (
  app text not null,
  day date not null,
  line text not null,
  trips int not null default 0,
  primary key (app, day, line)
);

alter table public.daily_line_stats enable row level security;
create policy daily_line_stats_admin_read on public.daily_line_stats
  for select to authenticated using (public.is_admin());

-- 0003 의 함수에 경로 열·노선별 집계를 더한 판. 규칙은 같다(바뀐 날만 통째로).
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

  if to_regclass('pg_temp.touched') is not null then  -- 같은 트랜잭션에서 두 번 불릴 때
    drop table pg_temp.touched;
  end if;
  create temp table touched on commit drop as
    select distinct app, (occurred_at at time zone 'Asia/Seoul')::date as day
    from public.events
    where created_at >= since - interval '10 minutes';

  with day_events as (
    select t.app, t.day, e.id, e.name, e.device_id, e.props
    from touched t
    join public.events e
      on e.app = t.app
     and e.occurred_at >= (t.day::timestamp at time zone 'Asia/Seoul')
     and e.occurred_at < ((t.day + 1)::timestamp at time zone 'Asia/Seoul')
  ), routed as (
    -- 노선 정보가 온전한 trip_started 만.
    select app, day,
           (props->>'transfers')::int as transfers,
           (props->>'stops')::int as stops
    from day_events
    where name = 'trip_started'
      and jsonb_typeof(props->'lines') = 'array'
      and props->>'transfers' ~ '^\d{1,3}$'
      and props->>'stops' ~ '^\d{1,4}$'
  ), route_agg as (
    select app, day,
           count(*) as route_trips,
           count(*) filter (where transfers > 0) as transfer_trips,
           sum(transfers) as transfers_sum,
           sum(stops) as stops_sum
    from routed
    group by app, day
  ), agg as (
    select
      d.app,
      d.day,
      count(*) filter (where d.name = 'trip_started') as trips,
      count(*) filter (where d.name = 'alert_fired') as alerts,
      count(*) filter (where d.name = 'trip_ended' and d.props->>'mode' = 'realtime') as realtime_trips,
      count(*) filter (where d.name = 'trip_ended' and d.props->>'mode' = 'fallback') as fallback_trips,
      coalesce(sum((d.props->>'api_calls')::int) filter (
        where d.name = 'trip_ended' and d.props->>'api_calls' ~ '^\d{1,9}$'), 0) as api_calls,
      count(distinct d.device_id) as devices,
      count(*) filter (where d.name = 'trip_ended' and d.props->>'mode' = 'timetable') as timetable_trips,
      count(*) filter (where d.name = 'trip_ended') as ended_trips,
      count(*) filter (where d.name = 'trip_ended' and d.props->>'reason' = 'arrived') as arrived_trips
    from day_events d
    group by d.app, d.day
  )
  insert into public.daily_stats as s (
    app, day, trips, alerts, realtime_trips, fallback_trips, api_calls, devices,
    timetable_trips, ended_trips, arrived_trips,
    route_trips, transfer_trips, transfers_sum, stops_sum, refreshed_at)
  select
    a.app, a.day, a.trips, a.alerts, a.realtime_trips, a.fallback_trips, a.api_calls, a.devices,
    a.timetable_trips, a.ended_trips, a.arrived_trips,
    coalesce(r.route_trips, 0), coalesce(r.transfer_trips, 0),
    coalesce(r.transfers_sum, 0), coalesce(r.stops_sum, 0), started
  from agg a
  left join route_agg r on r.app = a.app and r.day = a.day
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
    route_trips = excluded.route_trips,
    transfer_trips = excluded.transfer_trips,
    transfers_sum = excluded.transfers_sum,
    stops_sum = excluded.stops_sum,
    refreshed_at = excluded.refreshed_at;
  get diagnostics n = row_count;

  -- 노선별: 바뀐 날은 지우고 다시 넣는다(그날 안 쓴 노선 행이 남지 않게).
  delete from public.daily_line_stats l
  using touched t
  where l.app = t.app and l.day = t.day;

  insert into public.daily_line_stats (app, day, line, trips)
  select t.app, t.day, line.value, count(distinct e.id)
  from touched t
  join public.events e
    on e.app = t.app
   and e.name = 'trip_started'
   and e.occurred_at >= (t.day::timestamp at time zone 'Asia/Seoul')
   and e.occurred_at < ((t.day + 1)::timestamp at time zone 'Asia/Seoul')
   and jsonb_typeof(e.props->'lines') = 'array'
  cross join lateral jsonb_array_elements_text(e.props->'lines') as line(value)
  where line.value ~ '^[A-Za-z0-9_-]{1,16}$'
  group by t.app, t.day, line.value;

  update public.stats_refresh_state set refreshed_at = started;
  return n;
end;
$$;

revoke all on function public.refresh_daily_stats() from public, anon;
grant execute on function public.refresh_daily_stats() to authenticated;

-- 이미 들어온 이벤트로 새 열·노선 표를 채운다 (경로 정보는 새 앱부터라 대부분 0).
update public.stats_refresh_state set refreshed_at = '-infinity';
select public.refresh_daily_stats();
