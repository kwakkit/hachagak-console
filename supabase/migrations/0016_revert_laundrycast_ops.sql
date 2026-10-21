-- 0016 — 0015(런디캐스트를 하차각 콘솔 공용 표에 붙이기) 원복.
--
-- 런디캐스트는 하차각 콘솔에 붙이지 않고 전용 콘솔(laundrycast-console 저장소) + 전용 표(lc_notices·lc_app_config·
-- lc_feedback·lc_events, 0017)로 간다. 공용 표의 가드·CHECK·설정 행을 0015 이전(0003)대로 돌린다.
-- 0015 로 들어온 런디캐스트 제보·이벤트는 확인용뿐이었고 이미 지웠다(남아 있으면 아래에서 지운다).

delete from public.events where app = 'laundrycast';
delete from public.feedback where app = 'laundrycast';
delete from public.app_config where app = 'laundrycast';

alter table public.events
  add constraint events_name_check check (name in ('trip_started', 'alert_fired', 'trip_ended'));

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
