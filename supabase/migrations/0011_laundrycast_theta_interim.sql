-- 0011 — 런디캐스트 건조 기준값(θ) 임시 조정. 0단계 실측 보정 전까지.
--
-- 실서버 첫 확인(2026-10-20)에서 기상청 기반 ET0 가 10월 서울 9~16시 합 1.4~1.8mm 인데,
-- 초기 추정 θ(보통 1.0) ÷ 베란다 계수 0.5 = 2.0mm 가 필요해 "베란다는 거의 매일 안 마름"으로 나왔다.
-- 실제(셔츠 베란다 반나절)에 맞게 낮춘다: 얇음 0.6→0.3, 보통 1.0→0.5, 두꺼움 1.6→0.8.
-- 앱 ModelParams.fallback · Edge Function DEFAULT_PARAMS · tool/validation 도 같은 값.

update public.lc_model_params
set params = jsonb_set(params, '{theta}', '{"thin": 0.3, "normal": 0.5, "thick": 0.8}'::jsonb),
    fitted_at = null
where scope = 'kr';
