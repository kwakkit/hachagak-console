-- 0013 — 런디캐스트 중기예보(4~7일): 격자에 중기 구역, 예보 행에 출처, 등록 RPC 인자, 수집 cron.
--
-- 단기예보는 오늘~3일 뒤까지라 주간 화면 4일째부터 비었다. 기상청 중기예보는 육상 구역(오전·오후 하늘·강수확률)과
-- 기온 지점(하루 최저·최고)만 주므로, Edge Function 이 시간별 값을 근사해 같은 표에 source='mid' 로 넣는다.
-- 단기예보가 같은 시각을 받으면 단기예보가 덮어쓴다(중기 수집은 이미 있는 행을 덮지 않는다).

alter table public.lc_grid_cells
  add column if not exists mid_land_reg text check (mid_land_reg ~ '^[0-9A-Z]{8}$'),
  add column if not exists mid_ta_reg text check (mid_ta_reg ~ '^[0-9A-Z]{8}$');

alter table public.lc_forecast_hourly
  add column if not exists source text not null default 'vilage' check (source in ('vilage', 'mid'));

-- 등록 RPC: 중기 구역 인자 추가. 인자 목록이 바뀌어 같은 이름의 겹치는 함수가 생기지 않게 지우고 다시 만든다.
drop function if exists public.lc_register_device(int, int, text, text, text);

create function public.lc_register_device(
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

  select mid_land_reg is not null into v_had_mid
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

  -- 새 격자는 단기·중기를 바로 받고, 기존 격자에 중기 구역이 처음 붙으면 중기만 받는다.
  if v_new then
    perform public.lc_call_function('lc-collect-forecast');
  end if;
  if (v_new or not coalesce(v_had_mid, false)) and p_mid_land is not null then
    perform public.lc_call_function('lc-collect-mid');
  end if;

  return v_cell;
end;
$$;

revoke all on function public.lc_register_device(int, int, text, text, text, text, text) from public, anon;
grant execute on function public.lc_register_device(int, int, text, text, text, text, text) to authenticated;

create or replace view public.lc_active_cells with (security_invoker = true) as
select c.id, c.provider, c.nx, c.ny, c.tz, c.created_at, c.last_fetched_at, c.last_base_time,
       c.mid_land_reg, c.mid_ta_reg
from public.lc_grid_cells c
where exists (
  select 1 from public.lc_devices d
  where d.cell_id = c.id and d.last_seen_at > now() - interval '30 days'
);

-- 중기예보: 06·18시(KST) 발표 → 06:40·18:40(KST) = UTC 21:40·09:40.
select cron.schedule('laundrycast-collect-mid', '40 9,21 * * *',
  $$ select public.lc_call_function('lc-collect-mid') $$);
