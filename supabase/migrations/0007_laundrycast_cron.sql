-- 0007 — 런디캐스트 Edge Function 주기 실행(pg_cron → pg_net HTTP POST).
--
-- 함수는 x-cron-secret 헤더가 Edge Function 비밀값 CRON_SECRET 과 같을 때만 실행한다.
-- 같은 값을 Vault 에 'lc_cron_secret' 으로 둔다(마이그레이션·저장소에 값이 없음). 만들기:
--   select vault.create_secret('<값>', 'lc_cron_secret', 'laundrycast pg_cron -> Edge Functions');
--   supabase secrets set CRON_SECRET=<같은 값>
-- API 키(KMA_SERVICE_KEY·AIRKOREA_SERVICE_KEY·FCM_SERVICE_ACCOUNT)가 없으면 함수가 500 을 돌려줄 뿐 — 키를 넣는 순간 동작.
--
-- pg_cron 시각은 UTC. 한국 = UTC+9 이고 9 는 3 의 배수라, 기상청 발표 시각(KST 02·05·…·23시)과
-- UTC 02·05·…·23시가 같은 집합이다.

create extension if not exists pg_net with schema extensions;

create or replace function public.lc_call_function(p_name text)
returns bigint
language sql security definer set search_path = public, extensions
as $$
  select net.http_post(
    url := 'https://xsbdwhbrrvmdmpgzjdnm.supabase.co/functions/v1/' || p_name,
    headers := jsonb_build_object(
      'content-type', 'application/json',
      'x-cron-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'lc_cron_secret')
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 120000
  );
$$;

revoke all on function public.lc_call_function(text) from public, anon, authenticated;

-- 단기예보: 발표(매 3시간 02시~) + 10분 제공 지연 → 15분에.
select cron.schedule('laundrycast-collect-forecast', '15 2-23/3 * * *',
  $$ select public.lc_call_function('lc-collect-forecast') $$);

-- 미세먼지 예보: 에어코리아 05·11·17·23시(KST) 발표 → 30분에.
select cron.schedule('laundrycast-collect-dust', '30 2,8,14,20 * * *',
  $$ select public.lc_call_function('lc-collect-dust') $$);

-- 푸시: 10분마다(아침 알림 창 10분 — lc_morning_targets(10)).
select cron.schedule('laundrycast-send-push', '*/10 * * * *',
  $$ select public.lc_call_function('lc-send-push') $$);
