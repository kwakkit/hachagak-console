-- 0012 — 런디캐스트 "예상 변경" 알림(SCREENS.md §7): 널어 둔 빨래의 마를 시각이 30분 넘게 바뀌면 알린다.
-- predicted_dry_at(널 때의 예측)은 예측 정확도 집계에 쓰므로 덮어쓰지 않고, 알린 시각은 따로 둔다.

alter table public.lc_loads add column if not exists notified_dry_at timestamptz;
