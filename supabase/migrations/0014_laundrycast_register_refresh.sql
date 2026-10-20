-- 0014 — 런디캐스트: 다시 쓰이기 시작한 격자도 등록 즉시 단기예보 수집.
--
-- 0013 까지는 새 격자만 바로 수집했다. 30일 넘게 쉬던 격자는 행이 남아 있어 '새 격자'가 아니고,
-- 지난 예보는 2일 뒤 지워지므로 다음 정기 수집(최대 3시간)까지 앱이 "예보 준비 중"에 머물렀다.
-- 받은 발표 시각(last_base_time)이 6시간 넘게 지났으면 등록 때 바로 수집한다(중기도 같이 지워졌으므로 함께).
-- create or replace 라 권한(authenticated 만 실행)은 0013 그대로 유지된다.

create or replace function public.lc_register_device(
  p_nx int,
  p_ny int,
  p_dust_region text default null,
  p_locale text default 'ko',
  p_app_version text default null,
  p_mid_land text default null,
  p_mid_ta text default null
)
returns bigint
language plpgsql security definer set search_path = public
as $$
declare
  v_cell bigint;
  v_new boolean;
  v_had_mid boolean;
  v_last_base timestamptz;
  v_stale boolean;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  if p_nx not between 1 and 149 or p_ny not between 1 and 253 then
    raise exception 'grid out of range';
  end if;
  if p_mid_land is not null and p_mid_land !~ '^[0-9A-Z]{8}$'
     or p_mid_ta is not null and p_mid_ta !~ '^[0-9A-Z]{8}$' then
    raise exception 'bad mid region';
  end if;

  select mid_land_reg is not null, last_base_time into v_had_mid, v_last_base
  from public.lc_grid_cells where provider = 'kma' and nx = p_nx and ny = p_ny;

  insert into public.lc_grid_cells (provider, nx, ny, mid_land_reg, mid_ta_reg)
  values ('kma', p_nx, p_ny, p_mid_land, p_mid_ta)
  on conflict (provider, nx, ny) do update set
    mid_land_reg = coalesce(public.lc_grid_cells.mid_land_reg, excluded.mid_land_reg),
    mid_ta_reg = coalesce(public.lc_grid_cells.mid_ta_reg, excluded.mid_ta_reg)
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

  -- 새 격자 · 한동안 수집이 멈춘 격자(30일 넘게 쉬어 활성에서 빠졌던 곳 등)는 단기·중기를 바로 받는다.
  -- 기존 격자에 중기 구역이 처음 붙으면 중기만.
  v_stale := v_new or v_last_base is null or v_last_base < now() - interval '6 hours';
  if v_stale then
    perform public.lc_call_function('lc-collect-forecast');
  end if;
  if (v_stale or not coalesce(v_had_mid, false)) and p_mid_land is not null then
    perform public.lc_call_function('lc-collect-mid');
  end if;

  return v_cell;
end;
$$;

