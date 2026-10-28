-- 0018 — 런디캐스트 보관 기간(처리방침 "4. 보관 기간과 파기", laundrycast docs/privacy).
--
--   - 익명 계정: 마지막으로 앱을 연 날(lc_devices.last_seen_at)부터 1년 → 계정째 삭제.
--     lc_devices · lc_loads · lc_load_feedback · lc_push_log 는 FK cascade 로 함께 지워진다(lc_delete_me 와 같은 방식).
--     익명 계정(is_anonymous)만 — 관리자 등 이메일 계정은 건드리지 않는다.
--   - 문의·오류 제보(lc_feedback): 받은 날부터 1년.
--   - 사용 이벤트(lc_events) 90일은 0017 의 laundrycast-purge-old-events 가 이미 한다.
-- 매일 03:50 KST.

create or replace function public.lc_purge_inactive()
returns jsonb
language plpgsql security definer set search_path = public, auth
as $$
declare
  n_accounts int;
  n_feedback int;
begin
  with gone as (
    delete from auth.users u
    using public.lc_devices d
    where d.id = u.id
      and u.is_anonymous
      and d.last_seen_at < now() - interval '1 year'
    returning u.id
  )
  select count(*) into n_accounts from gone;

  delete from public.lc_feedback where created_at < now() - interval '1 year';
  get diagnostics n_feedback = row_count;

  return jsonb_build_object('accounts', n_accounts, 'feedback', n_feedback);
end;
$$;

revoke all on function public.lc_purge_inactive() from public, anon, authenticated;

select cron.schedule('laundrycast-purge-inactive', '50 18 * * *',  -- 매일 03:50 KST
  'select public.lc_purge_inactive()');
