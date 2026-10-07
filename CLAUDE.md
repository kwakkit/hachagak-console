# 하차각 콘솔 (hachagak_console)

하차각을 운영하는 관리자 대시보드. Flutter Web + Supabase(Postgres·Auth·RLS).
서버 코드 없음 — 권한은 전부 RLS. 세팅·실행은 [README.md](README.md).

## 현재 상태 (1주차 완료)

- `supabase/migrations/0001_init.sql` — `admins`, `notices`, `app_config`(key/value jsonb),
  `feedback`, `events`, `daily_stats` 뷰(Asia/Seoul 일별 집계, `security_invoker`).
  모든 테이블에 `app` 컬럼(현재 `'hachagak'`) — 나중에 앱이 늘어도 한 콘솔에서 다룰 여지.
  **아직 실제 Supabase 에서 실행해 보지 않음.**
- 화면: 로그인(이메일/비번, `admins` 에 없으면 차단) → 셸(넓으면 NavigationRail, 좁으면 NavigationBar)
  → 대시보드 / 공지 / 원격 설정 / 제보함.
- `flutter analyze` 0건, `flutter test` 통과, `flutter build web` 성공. GitHub `kwakkit/hachagak-console`(public) 에 push 됨.

## 명령

```bash
flutter run -d chrome --dart-define-from-file=dart_defines/local.json   # VS Code: "하차각 콘솔 (Chrome)"
flutter analyze && flutter test
flutter build web --dart-define-from-file=dart_defines/local.json
```

## 코드 규칙

- 구조: `lib/app/`(`app.dart` + `gate/`(인증 게이트·로딩·안내 화면)·`theme/`(테마·`themeModeProvider`)·
  `ui/`(공통 위젯)) · `lib/core/`(env, supabase) · `lib/features/<name>/`.
- **파일당 타입 1개 (하차각과 같은 규칙).** class/enum/mixin 은 파일 하나에 하나, private 보조 위젯도
  public 으로 두고 `<page>/<name>.dart` 에 분리해 `import` 한다(예: `notices_page/notice_row.dart`).
  예외: `StatefulWidget` 의 `State` 는 private 로 위젯과 같은 파일. 이름이 Flutter 내장과 겹치면 접두어
  (`DashboardTable`). 모델(`notice.dart`·`feedback_item.dart` 등)은 페이지 옆에 두고 페이지 파일이 `export`
  해 기존 import 경로 유지. provider·포맷터 같은 최상위 값은 관련 타입/페이지 파일에.
- **Supabase 호출은 `<feature>_repository.dart` 에만.** 저장소는 `SupabaseClient` 를 받는 클래스 +
  같은 파일의 `<feature>RepositoryProvider`(테스트에서 override). 페이지의 `FutureProvider` 는 저장소를
  `watch` 해 조회만 위임, 위젯의 쓰기는 `ref.read(...Provider).save/update/delete`. 위젯·페이지에서
  `db.from(...)` 직접 호출 금지(예외: `core/supabase.dart` 의 인증·관리자 확인).
- 상태관리 Riverpod 3 (`FutureProvider.autoDispose` + 쓰기 후 `ref.invalidate`). 코드 생성 안 씀.
- 비동기 화면은 `AsyncView`, 쓰기 작업은 `runWithSnack` (`lib/app/ui/async_view.dart`, 배럴에 포함).
- 페이지 공통 레이아웃 `PageScaffold(title, eyebrow)` (`lib/app/ui/page_scaffold.dart`, `wideBreakpoint` 720).
- **디자인 = 하차각 "관제실 콘솔"** — `lib/app/theme/`(`ConsolePalette` 라이트=청사진·다크=야간 관제실,
  `ConsoleFonts` Orbit/IBM Plex Sans KR/Mono, `consoleTheme`) + `lib/app/ui/` 위젯들
  (`ConsoleBackdrop`·`ConsolePanel`·`ConsoleEyebrow`·`ConsoleDot`·`StatusPill`·`BracketFrame`·`EmptyState`·`HorizontalScroll`(넓은 표 가로 스크롤)·
  `PageScaffold`, `themeModeProvider` 기본 라이트). 화면은 배럴 `lib/app/console_widgets.dart` 하나만 import. 색은 의미 있는 곳에만: 브랜드 보라 `accent`, 상태 `ok`/`warn`/`alert`. 카드 대신 `ConsolePanel`.
  한글 폰트는 웹 용량 때문에 KS X 1001 2,350자 서브셋(`assets/fonts/`), mono 스타일은 한글 폴백 지정.
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

## 3주차 — 이벤트 전송 → 대시보드 통계 ✅ 코드 완료 (실기기·Supabase 실전송 미검증)

- **하차각** (`lib/core/ops/`): 추적 isolate 가 `EventQueue` 에 이벤트마다 **고유 키**로 쌓고
  (`flutter_foreground_task` 스토리지 — Hive 는 isolate 간 공유 불가라 안 씀, 읽고 고쳐 쓰기 없음 → 경합 없음),
  메인 isolate 의 `OpsEventFlusher`(앱 시작·복귀)가 `EventUploader` 로 100건씩 `events` 에 POST 하고
  보낸 키만 지운다. 실패는 큐에 남겨 다음에 (fail-open). 최대 300건, 넘치면 오래된 것부터 버림.
- 이벤트: `trip_started`(사용자 시작만, OS 재시작 제외) · `alert_fired{kind: approaching|transfer|arrived}` ·
  `trip_ended{mode: realtime|fallback|timetable, api_calls, reason: arrived|stopped}`.
  역·경로·위치 없음. 기기 UUID·앱 버전은 전송 시 메인이 붙인다. `api_calls`·강등 여부는 `TripPlan` 에 영속.
- **콘솔**: `0002_daily_stats_trip_outcomes.sql`(2026-10-01 Supabase 적용) — `daily_stats` 끝에 `timetable_trips`·`ended_trips`·
  `arrived_trips` 추가. 대시보드 "도착 완료율" 타일, 표에 시간표 수·도착/종료 열.
  `DailyStat` 은 새 열이 없으면 0 (마이그레이션 전 DB 에서도 안 깨짐).

## 사용자 증가 대비 — `0003_scale_guards.sql` (로컬 Supabase 검증, **운영 미적용**)

- **앱 쓰기 남용 방어:** `events`·`feedback` BEFORE INSERT 트리거(security definer)가 검증 실패 행을
  `return null` 로 조용히 버린다 — CHECK 위반 400 이면 앱의 100건 배치가 큐에 남아 무한 재전송되기 때문.
  events: app·name 허용 목록, props 는 객체·512B 이하, occurred_at 은 30일 전~1시간 후, 기기당 시간당 300건.
  feedback: 기기당 하루 10건(기기 없음은 묶어서 30건), app_version·os 는 잘라서 저장. `created_at` 은 서버 시각 강제.
- **집계:** `daily_stats` 는 뷰 → 테이블. `refresh_daily_stats()` 가 지난 갱신 이후 `created_at` 기준으로
  새 이벤트가 걸친 날만 통째로 다시 센다(10분 겹침). pg_cron 매시 + 콘솔 대시보드 조회 직전(관리자만 실행 가능).
- **보관:** `purge_old_events()` 가 매일 90일 지난 원본 이벤트 삭제 — 30일보다 오래된 occurred_at 은 애초에
  안 받으므로 지워진 날의 집계는 다시 계산되지 않는다.
- 새 이벤트 이름·앱을 추가하면 `guard_event_insert` 의 허용 목록도 같이 고칠 것(안 고치면 조용히 버려짐).

## 경로 통계 (노선 단위) — `0004_route_stats.sql` (로컬 Supabase 검증, **운영 미적용**)

- **수집 범위 = Play 데이터 보안 양식 "앱 활동(앱 상호작용)" 안.** 하차각 `trip_started.props` 에
  `lines`(노선 id 순서대로)·`transfers`·`stops` 만. **역 이름·출발/도착역·위치는 받지 않는다** —
  보내면 "위치"·"앱 내 검색 기록" 신고 대상이 되고 핵심 제약 3과도 어긋난다.
- `daily_stats` 에 `route_trips`(노선 정보 있는 시작 여정)·`transfer_trips`·`transfers_sum`·`stops_sum`,
  새 표 `daily_line_stats(app, day, line, trips)` — 한 여정이 같은 노선을 두 번 타도 1, 노선 id 는
  `^[A-Za-z0-9_-]{1,16}$` 만(역 이름이 끼어들면 버림). `refresh_daily_stats()` 가 둘 다 갱신(0004 판).
- 콘솔: 대시보드 "경로 (최근 14일)" — `RouteTiles`(경로 정보 여정·평균 정거장·환승 여정 비율·평균 환승)
  + `LineUsagePanel`(노선별 막대, 비율 합은 100% 초과 가능) + 표에 "평균 정거장 / 환승 여정" 열.
  노선 이름·색은 `SubwayLine.all`(하차각 `seoul.json` 과 수동 동기화). 노선 정보 없는 옛 앱 여정은 평균에서 빠진다.

