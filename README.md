# 하차각 콘솔

하차각을 운영하는 관리자 대시보드. Flutter Web + Supabase.

| 화면      | 내용                                                                   |
| --------- | ---------------------------------------------------------------------- |
| 대시보드  | 오늘 여정·기기·API 호출·도착 완료율·폴백 비율·새 제보, 최근 14일 표    |
| 공지      | 작성·수정·삭제, 게시 기간                                              |
| 원격 설정 | `min_version` / `latest_version` / `realtime_enabled`(방법 A 긴급 OFF) |
| 제보함    | 상태(새 제보·확인 중·완료) 변경, 관리자 메모                           |

## 기술 스택

| 영역       | 사용 기술                                                                        |
| ---------- | -------------------------------------------------------------------------------- |
| 프론트엔드 | Flutter 3.47 (Web) · Dart 3.13 · Material 3                                      |
| 상태관리   | Riverpod 3 (`flutter_riverpod`, 코드 생성 없음)                                  |
| 백엔드     | Supabase — Postgres · Auth(이메일/비밀번호) · PostgREST (`supabase_flutter` 2)   |
| DB·권한    | PostgreSQL SQL 마이그레이션, Row Level Security 정책, `security_invoker` 집계 뷰 |
| 도구       | Supabase CLI(`supabase db push`), `flutter_lints`, `intl`(한국어 날짜)           |
| 폰트       | Orbit · IBM Plex Sans KR(KS X 1001 서브셋) · IBM Plex Mono — OFL 1.1             |

별도 서버 코드는 없다. 콘솔은 브라우저에서 Supabase 에 직접 붙고, 누가 무엇을 읽고 쓸 수 있는지는
전부 Postgres RLS 정책이 정한다.

| 테이블        | 용도                                 | 하차각 앱(anon)          | 관리자       |
| ------------- | ------------------------------------ | ------------------------ | ------------ |
| `admins`      | 콘솔 접근 허용 계정                  | —                        | 본인 행 읽기 |
| `notices`     | 홈 배너 공지                         | 게시 중인 것만 읽기      | 전체         |
| `app_config`  | 원격 설정 (key / jsonb value)        | 읽기                     | 전체         |
| `feedback`    | 문의·오류 제보                       | 추가만 (기기당 하루 10건) | 전체         |
| `events`      | 익명 사용 이벤트 (90일 보관)         | 추가만 (기기당 시간당 300건) | 읽기     |
| `daily_stats` | Asia/Seoul 일별 집계 (매시 갱신, 영구) | —                      | 읽기         |
| `daily_line_stats` | 노선별 일별 이용 여정 수 (0004)  | —                        | 읽기         |

앱 쓰기 검증(0003): `events`·`feedback` 의 BEFORE INSERT 트리거가 형식 이상·횟수 초과 행을
**오류 없이 버린다** — 앱의 일괄 전송 배치가 400 으로 통째 막히지 않게. 집계·보관은 pg_cron
(`refresh_daily_stats` 매시 5분, `purge_old_events` 매일 03:30 KST), 대시보드는 조회 직전에도 갱신.

## 처음 세팅

1. [supabase.com](https://supabase.com) 에서 프로젝트 생성 (Region: Seoul).
2. 스키마 적용 — Supabase CLI 로 `supabase link --project-ref <ref>` → `supabase db push`.
   (CLI 없이 하려면 SQL Editor 에 [`supabase/migrations/0001_init.sql`](supabase/migrations/0001_init.sql) 전체를 붙여 실행.)
   이후 스키마 변경은 새 마이그레이션 파일을 추가하고 `supabase db push`.
3. Authentication → Users → **Add user** 로 관리자 계정 생성 (Auto Confirm 체크).
4. SQL Editor 에서 관리자 등록:
   ```sql
   insert into public.admins (user_id)
   select id from auth.users where email = 'YOUR_EMAIL';
   ```
5. Authentication → Sign In / Providers 에서 **Allow new users to sign up 끄기**
   (콘솔은 가입 화면이 없고, 관리자 외 계정이 생길 이유가 없다).
6. Project Settings → API Keys 의 URL·Publishable key 를 `dart_defines/local.json` 에 입력
   (`example.json` 참고, `local.json` 은 git 제외).

## 실행

VS Code: 실행 및 디버그 → **하차각 콘솔 (Chrome)**. 또는

```bash
flutter run -d chrome --dart-define-from-file=dart_defines/local.json
```

## 구조

```
lib/
 ├── main.dart                 # Supabase 초기화
 ├── app/
 │    ├── app.dart             # MaterialApp
 │    ├── gate/                # 인증 게이트·로딩·안내 화면
 │    ├── theme/               # 관제실 콘솔 팔레트·폰트·테마, 라이트/다크 전환
 │    └── ui/                  # 공통 위젯(AsyncView·PageScaffold·ConsolePanel…)
 ├── core/                     # env(dart-define), supabase 클라이언트·세션·관리자 확인
 └── features/<name>/          # dashboard / notices / config / feedback / auth / shell
      ├── <name>_page.dart     # 화면 + 조회 provider
      ├── <name>_repository.dart  # Supabase 호출은 여기에만
      └── <name>_page/         # 화면 전용 하위 위젯
supabase/migrations/           # 스키마 + RLS (SQL)
```

## 보안 원칙

- 앱(anon)은 공지·설정 **읽기만**, 제보·이벤트 **쓰기만**. 나머지는 `admins` 에 있는 계정만 (RLS).
- 역 이름·경로·위치 등 이동 정보는 저장하지 않는다. 기기 식별은 앱이 만든 랜덤 UUID.
- Publishable key 는 공개돼도 되는 키. **secret key 는 절대 앱·콘솔에 넣지 않는다.**
