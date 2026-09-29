# 곽킷 콘솔 (kwakkit_console)

곽킷 앱(현재 하차각 하나)을 운영하는 관리자 대시보드. Flutter Web + Supabase(Postgres·Auth·RLS).
서버 코드 없음 — 권한은 전부 RLS. 세팅·실행은 [README.md](README.md).

## 현재 상태 (1주차 완료)

- `supabase/migrations/0001_init.sql` — `admins`, `notices`, `app_config`(key/value jsonb),
  `feedback`, `events`, `daily_stats` 뷰(Asia/Seoul 일별 집계, `security_invoker`).
  모든 테이블에 `app` 컬럼(현재 `'hachagak'`) — 곽킷 앱 여러 개를 한 콘솔에서.
  **아직 실제 Supabase 에서 실행해 보지 않음.**
- 화면: 로그인(이메일/비번, `admins` 에 없으면 차단) → 셸(넓으면 NavigationRail, 좁으면 NavigationBar)
  → 대시보드 / 공지 / 원격 설정 / 제보함.
- `flutter analyze` 0건, `flutter test` 통과, `flutter build web` 성공. GitHub `kwakkit/console`(public) 에 push 됨.

## 명령

```bash
flutter run -d chrome --dart-define-from-file=dart_defines/local.json   # VS Code: "곽킷 콘솔 (Chrome)"
flutter analyze && flutter test
flutter build web --dart-define-from-file=dart_defines/local.json
```

## 코드 규칙

- 구조: `lib/app/`(MaterialApp·인증 게이트·공통 위젯) · `lib/core/`(env, supabase) · `lib/features/<name>/`.
- 상태관리 Riverpod 3 (`FutureProvider.autoDispose` + 쓰기 후 `ref.invalidate`). 코드 생성 안 씀.
- 비동기 화면은 `AsyncView`, 쓰기 작업은 `runWithSnack` (`lib/app/async_view.dart`).
- 페이지 공통 레이아웃 `PageScaffold` (`lib/features/shell/console_shell.dart`).
- 브랜드 시드 `#6C3AE0` — 하차각과 동일.
- 키는 `--dart-define-from-file` 로 주입, `dart_defines/local.json` 은 git 제외.
  **Supabase secret key 는 앱·콘솔 어디에도 넣지 않는다** (Publishable key 만).

## 핵심 제약 (하차각과 합의된 원칙)

1. **하차각은 서버리스·온디바이스가 원칙.** 콘솔 연동이 이걸 깨면 안 된다.
2. **실패해도 앱은 정상 동작 (fail-open).** Supabase 가 죽어도 하차각 핵심 기능에 영향 0.
   원격 설정은 타임아웃 3초 → Hive 캐시 → 기본값 순.
3. **개인 이동 정보 수집 금지.** 역 이름·경로·위치는 절대 전송 안 함.
   기기 식별은 광고 ID 가 아닌 앱이 만든 랜덤 UUID.
4. 앱(anon)은 `notices`·`app_config` **읽기만**, `feedback`·`events` **쓰기만**.

## 2주차 — 하차각 연동 (`../hacha-gak`) ✅ 코드 완료 (하차각 main `e270dfd`, Supabase 실연결 미검증)

구현 요약은 하차각 `CLAUDE.md` 의 `lib/core/ops/` 항목. 계획과 다른 점: `supabase_flutter` 대신
이미 있는 dio 로 PostgREST 직접 호출(조회 2·추가 1뿐이라 auth/realtime 의존 불필요).
아래는 원래 계획(참고용).

작업 위치는 `hacha-gak/lib/core/ops/` (신규). 하차각 `CLAUDE.md`·`docs/DESIGN.md` 규칙을 따른다.

1. 의존성: `supabase_flutter` 추가 (URL·키는 하차각 `dart_defines/*.json` 에 `SUPABASE_URL`,
   `SUPABASE_PUBLISHABLE_KEY` 추가). 키 없으면 ops 전체 비활성 — 기존 `SEOUL_OPENAPI_KEY` 처리와 같은 방식.
2. **원격 설정** — 앱 시작 시 `app_config`(app='hachagak') 조회, 3초 타임아웃, Hive 캐시.
   - `realtime_enabled=false` 면 방법 A 비활성: `tracking_task_handler.dart` 의
     "키 없거나 설정 OFF 면 비활성" 조건에 원격 플래그를 세 번째 조건으로 추가.
     isolate 에는 `TripPlan`/saveData 로 값을 넘긴다 (isolate 에서 네트워크 추가 금지).
3. **버전 체크** — `package_info_plus`(이미 있음)로 현재 버전 비교.
   `< min_version` → 막는 다이얼로그(스토어 이동), `< latest_version` → 닫을 수 있는 안내.
4. **공지 배너** — 게시 중 공지를 홈 상단 배너로, 닫은 공지 id 는 Hive 에 기억.
5. **제보 폼** — 설정 화면에 "문의·오류 제보" 타일 → 카테고리(bug/idea/etc) + 메시지,
   앱 버전·OS 자동 첨부. 오프라인이면 실패 안내(3주차에 큐로 개선 가능).
6. 3주차 예고: 이벤트는 `trip_started`, `alert_fired{kind}`, `trip_ended{mode: realtime|fallback, api_calls}`
   3종만. 추적 isolate 는 Hive 큐에 쌓기만 하고 **다음 앱 실행 때 메인 isolate 가 일괄 전송**.
7. 출시 전: 개인정보처리방침·Play 데이터 보안 양식에 "앱 활동·진단 정보" 수집 추가 고지.
