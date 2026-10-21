-- 0015 — 런디캐스트를 콘솔 공지·원격설정·제보함·이벤트에 붙인다(laundrycast CLAUDE.md "운영 대시보드").
--
-- 공지·원격설정은 app 칼럼으로 이미 나뉘어 있어 행만 넣으면 된다. 제보·이벤트는 가드가 'hachagak' 만
-- 받고 이벤트 이름 CHECK 가 하차각 이름뿐이라 넓힌다. 이름 검증은 앱별로 가드에서 — CHECK 위반은
-- 배치 전체 400(독 배치, 0003 참고)이므로 CHECK 는 없애고 가드가 조용히 버린다.
--
-- 런디캐스트 이벤트는 DB 에 없는 것만: onboarding_done · push_opened{kind} · notification_permission{granted}.
-- 위치·격자 id 는 넣지 않는다. device_id 는 앱이 만든 랜덤 UUID 로, lc_devices(익명 계정)와 연결되지 않는다.

alter table public.events drop constraint if exists events_name_check;

create or replace function public.guard_event_insert()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  recent int;
begin
  if not (
       (new.app = 'hachagak' and new.name in ('trip_started', 'alert_fired', 'trip_ended'))
    or (new.app = 'laundrycast' and new.name in ('onboarding_done', 'push_opened', 'notification_permission'))
  )
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

create or replace function public.guard_feedback_insert()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  recent int;
  daily_cap int := case when new.device_id is null then 30 else 10 end;
begin
  if new.app is null or new.app not in ('hachagak', 'laundrycast') then
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

-- 원격 설정 기본값 — 버전 체크(앱 pubspec 1.0.0). 이미 있으면 그대로.
insert into public.app_config (app, key, value, description) values
  ('laundrycast', 'min_version', '"1.0.0"', '이보다 낮으면 강제 업데이트'),
  ('laundrycast', 'latest_version', '"1.0.0"', '이보다 낮으면 업데이트 권장')
on conflict (app, key) do nothing;
