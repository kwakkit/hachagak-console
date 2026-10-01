-- 3주차: 하차각 이벤트 전송 — trip_ended 의 새 값(mode=timetable, reason)을 집계에 추가.
-- create or replace view 는 기존 열 뒤에 새 열을 덧붙이는 것만 허용하므로 순서를 유지한다.
--
-- trip_ended.props:
--   mode      realtime(열차 확정 후 끝까지 실시간) / fallback(실시간 켰지만 강등·중단·확정 전 종료)
--             / timetable(처음부터 시간표 — 키·설정·원격 스위치 OFF)
--   api_calls 이번 여정의 서울 Open API 호출 수
--   reason    arrived(도착) / stopped(사용자 정지)

create or replace view public.daily_stats with (security_invoker = true) as
select
  app,
  (occurred_at at time zone 'Asia/Seoul')::date as day,
  count(*) filter (where name = 'trip_started') as trips,
  count(*) filter (where name = 'alert_fired') as alerts,
  count(*) filter (where name = 'trip_ended' and props->>'mode' = 'realtime') as realtime_trips,
  count(*) filter (where name = 'trip_ended' and props->>'mode' = 'fallback') as fallback_trips,
  coalesce(sum((props->>'api_calls')::int) filter (where name = 'trip_ended'), 0) as api_calls,
  count(distinct device_id) as devices,
  -- 0002 추가
  count(*) filter (where name = 'trip_ended' and props->>'mode' = 'timetable') as timetable_trips,
  count(*) filter (where name = 'trip_ended') as ended_trips,
  count(*) filter (where name = 'trip_ended' and props->>'reason' = 'arrived') as arrived_trips
from public.events
group by app, day;
