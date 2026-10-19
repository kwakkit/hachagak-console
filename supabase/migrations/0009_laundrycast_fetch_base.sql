-- 0009 — 런디캐스트 수집: "받은 시각"이 아니라 "받은 발표 시각"으로 건너뛰기 판정.
-- last_fetched_at(받은 시각)으로 비교하면, 새 격자 즉시 수집(0008)이 발표 직후 10분 안에 돌 때
-- 직전 발표를 받고도 이번 발표를 받은 것으로 보여 3시간 묵은 예보가 남는다(리뷰 지적).

alter table public.lc_grid_cells add column if not exists last_base_time timestamptz;

-- 수집 함수가 하루 호출 상한을 셀 수 있게(기상청 개발계정 일 10,000회 — 함수가 9,000 에서 멈춘다).
create index if not exists lc_fetch_log_provider_created_idx
  on public.lc_fetch_log (provider, created_at);
