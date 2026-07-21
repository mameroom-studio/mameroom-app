# Mameroom 개인정보 처리 감사 및 출시 전 점검

감사일: 2026-07-21  
대상 앱 정책: 개인정보처리방침 v1.0  
연결 프로젝트: `MemoryRoom` (`zglfjvnjnopilhikkxum`)  
주의: 이 문서는 코드·읽기 전용 DB 조회 결과다. 계약, Dashboard 로그 보존 설정, 실제 법인 정보는 별도 확인이 필요하다. 운영 DB·Storage에는 이번 작업으로 변경을 적용하지 않았다.

## 1. 현재 개인정보 처리 현황

- 인증: Supabase Auth 이메일/비밀번호 가입·로그인. 이메일 확인 흐름이 있다. Google 버튼 UI는 있으나 OAuth datasource 구현은 확인되지 않았다.
- 가입 수집: 이메일, 비밀번호, 닉네임. 변경 후 Auth user metadata에 닉네임, `age_14_confirmed_at`, `policy_version`, `terms_version`, `privacy_version`을 전달한다. 생년월일은 수집하지 않는다.
- 학습자료: 비공개 `materials`, `pdf_uploads`, `study-materials` bucket이 존재한다. Flutter 업로드 코드는 주로 `pdf_uploads`/`materials`를 사용한다. `study_materials.storage_path`, `raw_text`, `structured_text`에 경로와 추출 결과를 저장한다.
- AI: Edge Function이 `https://api.openai.com/v1/responses`와 통신한다. 기본 모델은 `gpt-4.1-mini`이고 `OPENAI_MODEL` 환경변수로 변경 가능하다.
- 결제: Google Play gateway는 TODO 골격이고 현재 실제 Billing 패키지/구매 검증 연동은 없다. Premium은 mock 흐름이다.
- 분석·광고·Crash·Push SDK: pubspec/Manifest에서 Firebase, Crashlytics, Sentry, 광고, Push SDK를 확인하지 못했다.
- 문의: `support_inquiries`에 `app_version`, `platform`, `locale`, `current_route`가 저장된다.
- 알림: 현재 Flutter 메모리 데모 구조이며 운영 `notifications` 테이블은 없다.

## 2. 개인정보처리방침 적용 화면

`PrivacyPolicyPage`에 17개 필수 목차, 목차 이동, 스크롤, SelectableText, Screen Reader용 Semantics, 최대 본문 폭, 작은 화면 패딩, 버전·공고일·시행일을 구현했다. WebView/외부 HTML은 사용하지 않는다. 설정 메뉴와 비로그인 가입 화면에서 접근 가능하다.

## 3. 확정 정책과 Placeholder

다음 값은 실제 정보로 확인할 때까지 유지한다.

- [회사명 또는 사업자명]
- [대표자]
- [사업자등록번호]
- [사업자 주소]
- [개인정보 보호책임자]
- [개인정보 문의 이메일]
- [Supabase 프로젝트 Region]
- [OpenAI 이전 국가 및 계약 정보]
- [공고일]
- [시행일]

CLI에서 연결 프로젝트 Region은 `ap-northeast-1`로 확인했지만, 출시 문서 치환은 계약·Dashboard 재확인 후 수행해야 한다.

## 4. 회원가입 만 14세 확인

- 14세, 이용약관, 개인정보처리방침을 각각 필수 체크로 분리했다.
- 세 항목 모두 기본값은 `false`다.
- 하나라도 미확인하면 가입 요청을 보내지 않는다.
- 이용약관과 개인정보처리방침 각각 `보기` 링크를 제공한다.
- 가입 요청의 Auth metadata에 확인 시각과 v1.0 버전을 기록한다.
- 기존 사용자는 기록이 없으므로 최초 로그인 재동의 또는 별도 additive migration이 필요하다. 이번 작업에서 운영 DB에는 적용하지 않았다.

## 5. 학습자료 원본 삭제 흐름

현재 배포 상태와 로컬 기존 코드 모두 정책과 불일치한다. `analyze-pdf`는 Storage에서 PDF를 내려받고 text layer를 추출한 뒤 `raw_text`/`structured_text`와 `status=generating`을 저장하지만 원본을 삭제하거나 `storage_path`를 null 처리하지 않는다. 재시도와 동일 `file_hash` cache도 원본 경로를 전제로 한다.

이번 로컬 보완은 Edge 로그·응답에서 원문/페이지 미리보기와 Storage 경로 출력을 제거한 것까지다. 원본 삭제는 상태/FK/재시도 계약 없이 즉시 넣으면 데이터 손실 위험이 있어 배포하지 않았다.

필요한 additive 변경안:

- `source_deleted_at timestamptz`
- `source_delete_status text` (`pending`, `deleted`, `retry_required`)
- `source_delete_error text`에는 사용자 원문·경로를 넣지 않고 정규화한 오류 코드만 저장
- 추출 텍스트 DB 저장 → 서버 Storage remove → remove 응답 확인 → `storage_path=null`, `source_deleted_at`, 다음 상태 전환
- 삭제 실패 시 `completed`/`generating`으로 숨기지 않고 재처리 queue 대상 표시

## 6. 분석 실패 파일 삭제 정책

현재 실패 시 `status=failed`, `raw_text=null`, `structured_text=null`로 변경할 뿐 Storage 원본은 삭제하지 않는다. timeout·클라이언트 취소 시 Edge Function의 catch가 실행되지 않을 수 있어 고아 파일이 생길 수 있다. 운영 전 서버 예약 작업으로 `source_delete_status=pending/retry_required` 또는 일정 시간 이상 parsing/uploading 상태의 객체를 소유권 검증 후 삭제하는 sweeper가 필요하다.

## 7. 자료 삭제 범위

실제 DB FK 읽기 결과 `study_materials` 삭제 시 다음이 CASCADE다.

- `concepts`
- `questions`
- `quiz_attempts`
- `memory_states`
- `review_schedules`
- `learning_passes`

`question_feedback`는 question FK를 통해 간접 CASCADE된다. Storage 객체는 DB 트랜잭션과 자동 연동되지 않는다. 현재 Flutter는 DB 행을 먼저 삭제한 후 클라이언트에서 Storage 삭제를 시도하고, Storage 실패를 로그만 남긴다. 따라서 원본 고아 객체가 생길 수 있으며 정책과 불일치한다. 실제 DB에는 소유권 검증 삭제 RPC가 없다.

운영 적용 전에는 service-role Edge Function 또는 서버 orchestration으로 (1) 소유권 확인, (2) 대상/경로 snapshot, (3) Storage 삭제, (4) DB 삭제를 수행하고 부분 실패를 재처리 가능하게 기록해야 한다.

## 8. 회원 탈퇴 삭제 범위

실제 DB에 탈퇴/계정 삭제 함수는 없다. profiles, 친구 요청·관계·차단, 학습 데이터, 룸/인벤토리, wallet/coin, 업적, 기억씨앗, 문의 등 다수 FK가 `auth.users on delete cascade`이지만 Storage 객체는 cascade되지 않는다. Auth를 먼저 삭제하면 `auth.uid()` 소유권 검증과 Storage 경로 수집이 불가능해질 수 있다.

안전한 서버 순서:

1. 재인증/명시적 탈퇴 확인
2. user UUID 기준 삭제 대상과 Storage 경로 snapshot
3. 법정 보존 대상이 실제 존재할 경우 별도 restricted schema로 분리
4. 사용자 서비스 데이터 삭제
5. Storage 삭제 및 결과 확인
6. Admin API로 Auth 사용자 삭제
7. 작업 결과/재시도 상태 반환
8. 클라이언트 sign-out

현재 앱에는 탈퇴 호출 경로가 없으므로 회원 탈퇴 정책은 아직 구현되지 않았다.

## 9. 법정 보존정보

요구 정책은 계약·청약철회 5년, 결제·재화 공급 5년, 소비자 불만·분쟁 3년, 표시·광고 6개월이다. 현재 실제 Google Play 결제는 미구현이고 법정 보존 전용 schema/table/access role도 없다. 일반 사용자 테이블에 남겨두는 soft delete는 허용되지 않는다. 실제 결제 출시 전 별도 restricted retention 설계와 접근감사가 필요하다.

## 10. 외부 위탁업체·SDK

| 구성 | 실제 확인 | 분류 |
|---|---|---|
| Supabase Auth/DB/Storage/Edge | 사용 | 처리위탁, Region에 따라 국외 이전 |
| OpenAI Responses API | Edge Function에서 사용 | 처리위탁, 계약에 따라 국외 이전 |
| Google Play Billing | gateway TODO, 실제 패키지 없음 | 현재 미처리; 도입 시 처리위탁 |
| file_picker/image_picker | 기기 파일 선택 | 앱 권한/로컬 처리, 별도 서버 SDK 아님 |
| package_info_plus | 앱 버전 조회 가능 | 기기/앱 정보 |
| SharedPreferences | quiz checkpoint 로컬 저장 | 기기 내 저장 |
| 광고/Analytics/Crash/Push | 확인되지 않음 | TODO: 출시 artifact와 Play Console 재검증 |

Supabase/OpenAI/Google 법인명, 계약 당사자, API 보존 옵션은 저장소로 확인할 수 없으므로 추정하지 않는다.

## 11. 국외 이전 확인 필요사항

- Supabase Dashboard의 실제 Project Region과 계약 법인/하위처리자 목록
- OpenAI API 계약 주체, 처리 위치, Zero Data Retention/Modified Abuse Monitoring 승인 여부
- Edge Function 및 DB backup/log 실제 보존기간
- Google Play 실제 merchant 계약 및 Billing 도입 여부
- 고객 문의/서버 로그의 IP·User-Agent 저장·보존 설정

## 12. 방침과 실제 코드의 불일치

| 항목 | 실제 처리 | 일치 | 조치 |
|---|---|---:|---|
| PDF 원본 추출 후 삭제 | 원본 유지 | 아니오 | 서버 삭제 상태·재시도 도입 |
| 실패 파일 영구 미보관 | 실패 시 원본 유지 가능 | 아니오 | 실패 cleanup/sweeper |
| 자료 삭제 | DB 먼저 삭제, Storage 실패 숨김 | 아니오 | 서버 orchestration |
| 회원 탈퇴 전체 삭제 | 호출 경로/함수 없음 | 아니오 | 탈퇴 Edge Function 필요 |
| 14세 필수 확인 | 이번 변경으로 UI/metadata 구현 | 부분 | 기존 사용자 재동의 필요 |
| 정책 상시 접근 | 이번 변경으로 설정/가입 링크 구현 | 예 | Placeholder 치환 필요 |
| 원문 로그 금지 | analyze-pdf preview 제거 | 부분 | 다른 Edge 오류 cause 및 Flutter filename/path 로그 추가 정리 |
| AI 전송 공개 | raw/structured text가 OpenAI로 전송됨 | 문서 반영 | 계약 정보 확정 필요 |
| 제3자 제공 없음 | 사용자간 학습자료 공개 경로 없음 | 예 | 운영 정책 지속 확인 |
| 공개 프로필 | 친구 검색/Room RPC가 제한 필드 반환 | 부분 | 공개 필드 목록 정책 고정 |
| 결제 purchase token | 실제 Billing 미구현 | 해당 없음 | 도입 시 즉시 방침/Data Safety 갱신 |

## 13. 수정·생성 파일

- 개인정보처리방침 화면, router, 설정 진입
- 회원가입 3개 필수 확인과 Auth metadata 전달 계층
- 개인정보/가입 Widget Test
- `analyze-pdf` 원문·페이지 preview/Storage path 로그·응답 제거
- 본 감사 문서

## 14. Migration 및 Edge Function 변경

- 운영 Migration 적용: 없음
- 운영 Storage 변경: 없음
- Edge Function 배포: 없음
- 로컬 Edge 변경: 민감 preview/path 로그 제거
- 필요한 후속 Migration: source 삭제 상태 컬럼, 삭제 job 상태, 기존 사용자 동의 이력(기존 구조 확인 후)
- 필요한 후속 Edge Function: 자료 삭제 orchestration, 회원 탈퇴 orchestration, 고아 원본 sweeper

## 15. 테스트 결과

- 개인정보처리방침/가입/설정/이용약관 관련 Widget Test 23건 통과
- 대상 Flutter 정적 분석 통과
- 실제 DB 감사 쿼리는 읽기 전용으로 실행
- 원본 Storage 삭제, 자료 전체 삭제, 회원 탈퇴 실제 동작 테스트는 구현 전이므로 미통과/미검증

## 16. Android·Web 빌드 결과

- Android debug APK: 성공 (`build/app/outputs/flutter-apk/app-debug.apk`)
- Web release build: 성공 (`build/web`)
- Web Wasm dry run: 성공
- 경고: CupertinoIcons font asset 미포함, file_picker/package_info_plus의 향후 Built-in Kotlin 전환 필요

## 17. Google Play Data Safety 작성표

| 데이터 유형 | 수집 | 공유 | 필수/선택 | 목적 | 전송 암호화 | 삭제 요청 | 비고 |
|---|---:|---:|---|---|---:|---:|---|
| 이메일/사용자 ID | 예 | 아니오 | 필수 | 계정·인증 | 예(HTTPS) | 계정 삭제 필요 | Supabase 처리 |
| 닉네임/프로필 | 예 | 제한 공개 | 필수 | 서비스·친구 기능 | 예 | 필요 | 친구 검색 공개 범위 확인 |
| 학습 PDF/추출 텍스트 | 예 | 아니오 | 기능 선택 | AI 학습자료 분석 | 예 | 자료/계정 삭제 필요 | OpenAI 위탁 전송 |
| 생성 문제·답안·학습 활동 | 예 | 아니오 | 기능 선택 | 학습·복습 | 예 | 필요 | DB 저장 |
| 앱 버전/platform/locale/current route | 문의 시 예 | 아니오 | 문의 시 필수 | 고객지원 | 예 | 문의/계정 삭제 | support inquiry |
| 친구·차단 정보 | 예 | 제한 처리 | 기능 선택 | 소셜 기능 | 예 | 계정 삭제 | 다른 이용자와 관계 정보 |
| 룸/인벤토리/M-Coin 기록 | 예 | Room 일부 제한 공개 | 기능 선택 | 게임화 | 예 | 계정 삭제 | 실제 현금결제 아님 |
| 진단/IP/User-Agent | 서버에서 가능 | 아니오 | 자동 | 보안·오류 대응 | 예 | 정책 확인 필요 | Dashboard 보존 설정 TODO |
| 결제정보/purchase token | 현재 아니오 | 현재 아니오 | 해당 없음 | TODO | TODO | TODO | Billing 도입 시 재작성 |
| 광고 ID/정밀 위치/연락처/사진 | 확인된 수집 없음 | 없음 | 해당 없음 | 해당 없음 | 해당 없음 | 해당 없음 | image picker는 현재 지원 정책과 충돌 여부 재검토 |

“공유” 여부의 Play 정의는 서비스 제공자 처리 예외 적용 조건을 Play Console 최신 안내와 계약으로 최종 확인해야 한다.

## 18. 운영 DB 적용 전 조건

1. source 삭제 상태와 허용 status constraint 확인
2. 실제 Storage object name 규칙과 모든 bucket 사용처 통일
3. 자료 삭제/탈퇴 대상 테이블 전체 FK snapshot
4. 법정 보존 실제 대상과 restricted schema 승인
5. service-role Edge Function secret 설정(앱 포함 금지)
6. Temp 사용자·파일로 성공/실패/timeout/재시도/타인 차단 DB·Storage 통합 테스트
7. 운영자 재처리 모니터링 및 idempotency 검증
8. 승인된 additive migration과 Edge 배포를 순서대로 별도 실행

## 19. 출시 전 반드시 교체할 Placeholder

`[회사명 또는 사업자명]`, `[대표자]`, `[사업자등록번호]`, `[사업자 주소]`, `[개인정보 보호책임자]`, `[개인정보 문의 이메일]`, `[Supabase 프로젝트 Region]`, `[OpenAI 이전 국가 및 계약 정보]`, `[공고일]`, `[시행일]`.

CI에서 위 문자열이 release build asset/source에 남아 있으면 실패시키는 검사를 권고한다.

## 20. 잔여 위험과 권고

- 가장 높은 위험은 “원본 삭제” 정책과 실제 Storage 유지의 불일치다. 정책 시행 전 서버 삭제 흐름을 먼저 완료해야 한다.
- 회원 탈퇴가 미구현이므로 계정 삭제 제공 의무를 충족하지 못한다.
- Flutter upload debug 로그가 파일명·Storage path·exception stack을 출력할 수 있다. release에서 제거되는지 의존하지 말고 구조화된 비식별 코드 로그로 교체해야 한다.
- Edge Function 오류 직렬화가 OpenAI 응답 body/cause를 포함할 수 있어 payload 노출 위험이 남는다.
- 세 bucket의 역사적 용도가 혼재한다. 실제 object 수와 owner prefix를 읽기 전용으로 조사한 후 통합/cleanup 계획이 필요하다.
- 실제 계약·Dashboard 보존 설정 확인 없이 국외 이전/보유기간을 확정해 게시하면 안 된다.