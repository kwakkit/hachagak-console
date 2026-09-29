# 곽킷 콘솔

곽킷 앱(현재 하차각)을 운영하는 관리자 대시보드. Flutter Web + Supabase.

| 화면 | 내용 |
|---|---|
| 대시보드 | 오늘 여정·기기·API 호출·폴백 비율·새 제보, 최근 14일 표 |
| 공지 | 작성·수정·삭제, 게시 기간 |
| 원격 설정 | `min_version` / `latest_version` / `realtime_enabled`(방법 A 긴급 OFF) |
| 제보함 | 상태(새 제보·확인 중·완료) 변경, 관리자 메모 |

## 처음 세팅

1. [supabase.com](https://supabase.com) 에서 프로젝트 생성 (Region: Seoul).
2. SQL Editor 에 [`supabase/migrations/0001_init.sql`](supabase/migrations/0001_init.sql) 전체를 붙여 실행.
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

VS Code: 실행 및 디버그 → **곽킷 콘솔 (Chrome)**. 또는

```bash
flutter run -d chrome --dart-define-from-file=dart_defines/local.json
```

## 구조

```
lib/
 ├── main.dart                 # Supabase 초기화
 ├── app/                      # MaterialApp, 인증 게이트, 공통 위젯(AsyncView)
 ├── core/                     # env(dart-define), supabase 클라이언트·세션·관리자 확인
 └── features/                 # dashboard / notices / config / feedback / auth / shell
supabase/migrations/           # 스키마 + RLS
```

## 보안 원칙

- 앱(anon)은 공지·설정 **읽기만**, 제보·이벤트 **쓰기만**. 나머지는 `admins` 에 있는 계정만 (RLS).
- 역 이름·경로·위치 등 이동 정보는 저장하지 않는다. 기기 식별은 앱이 만든 랜덤 UUID.
- Publishable key 는 공개돼도 되는 키. **secret key 는 절대 앱·콘솔에 넣지 않는다.**
