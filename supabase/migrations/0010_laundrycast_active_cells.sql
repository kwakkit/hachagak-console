-- 0010 — lc_active_cells 다시 만들기. `select c.*` 뷰는 만든 때의 칼럼만 담아서
-- 0009 에서 더한 last_base_time 이 안 보인다. 칼럼을 명시해 다시 정의한다.

create or replace view public.lc_active_cells with (security_invoker = true) as
select c.id, c.provider, c.nx, c.ny, c.tz, c.created_at, c.last_fetched_at, c.last_base_time
from public.lc_grid_cells c
where exists (
  select 1 from public.lc_devices d
  where d.cell_id = c.id and d.last_seen_at > now() - interval '30 days'
);
