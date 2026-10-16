-- 0008 — 새 격자가 처음 등록되면 예보 수집을 바로 한 번 부른다.
-- 정기 수집은 3시간마다라, 처음 동네를 고른 사용자가 최대 3시간 "예보 준비 중"을 보게 되기 때문.
-- 수집 함수는 이미 받은 격자를 건너뛰므로 추가 비용은 새 격자 한 칸뿐.

create or replace function public.lc_register_device(
  p_nx int,
  p_ny int,
  p_dust_region text default null,
  p_locale text default 'ko',
  p_app_version text default null
)
returns bigint
language plpgsql security definer set search_path = public
as $$
declare
  v_cell bigint;
  v_new boolean;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  if p_nx not between 1 and 149 or p_ny not between 1 and 253 then
    raise exception 'grid out of range';
  end if;

  insert into public.lc_grid_cells (provider, nx, ny)
  values ('kma', p_nx, p_ny)
  on conflict (provider, nx, ny) do update set nx = excluded.nx
  returning id, (xmax = 0) into v_cell, v_new;

  insert into public.lc_devices (id, cell_id, dust_region, locale, app_version, last_seen_at)
  values (auth.uid(), v_cell, left(p_dust_region, 16), left(coalesce(p_locale, 'ko'), 16),
          left(p_app_version, 32), now())
  on conflict (id) do update set
    cell_id = excluded.cell_id,
    dust_region = excluded.dust_region,
    locale = excluded.locale,
    app_version = excluded.app_version,
    last_seen_at = now();

  -- 새 격자: 지금 바로 수집(비동기 HTTP — 등록 응답을 기다리게 하지 않는다).
  if v_new then
    perform public.lc_call_function('lc-collect-forecast');
  end if;

  return v_cell;
end;
$$;

revoke all on function public.lc_register_device(int, int, text, text, text) from public, anon;
grant execute on function public.lc_register_device(int, int, text, text, text) to authenticated;
