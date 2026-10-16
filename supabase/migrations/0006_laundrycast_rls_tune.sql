-- 0006 — 0005 에 대한 Supabase advisor 지적 반영(런디캐스트 표만).
--   1) lc_my_cell() 을 anon 이 부를 이유가 없다 → anon·public 실행 권한 회수(정책 평가에 authenticated 만 필요).
--   2) auth_rls_initplan: 정책 안의 auth.uid() 를 (select auth.uid()) 로 — 행마다가 아니라 쿼리당 한 번 계산.

revoke all on function public.lc_my_cell() from public, anon;
grant execute on function public.lc_my_cell() to authenticated;

drop policy lc_devices_own on public.lc_devices;
create policy lc_devices_own on public.lc_devices
  for all to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

drop policy lc_loads_own_read on public.lc_loads;
create policy lc_loads_own_read on public.lc_loads
  for select to authenticated using (device_id = (select auth.uid()) or public.is_admin());

drop policy lc_loads_own_insert on public.lc_loads;
create policy lc_loads_own_insert on public.lc_loads
  for insert to authenticated with check (
    device_id = (select auth.uid())
    and hung_at between now() - interval '3 days' and now() + interval '10 minutes'
  );

drop policy lc_loads_own_update on public.lc_loads;
create policy lc_loads_own_update on public.lc_loads
  for update to authenticated
  using (device_id = (select auth.uid())) with check (device_id = (select auth.uid()));

drop policy lc_loads_own_delete on public.lc_loads;
create policy lc_loads_own_delete on public.lc_loads
  for delete to authenticated using (device_id = (select auth.uid()));

drop policy lc_load_feedback_own_read on public.lc_load_feedback;
create policy lc_load_feedback_own_read on public.lc_load_feedback
  for select to authenticated using (
    public.is_admin()
    or exists (select 1 from public.lc_loads l where l.id = load_id and l.device_id = (select auth.uid()))
  );

drop policy lc_load_feedback_own_insert on public.lc_load_feedback;
create policy lc_load_feedback_own_insert on public.lc_load_feedback
  for insert to authenticated with check (
    exists (select 1 from public.lc_loads l where l.id = load_id and l.device_id = (select auth.uid()))
  );
