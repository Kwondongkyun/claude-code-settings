---
name: frontend-review-security
description: Use when reviewing React/Next.js code for security vulnerabilities. Covers XSS, injection, auth flaws, sensitive data exposure, environment variable misuse, and dependency risks.
allowed-tools: Read, Glob, Grep
---

# 보안 취약점 탐지

## 입력 검증 미비

```typescript
// ❌ 사용자 입력 직접 사용
const searchUrl = `/api/search?q=${userInput}`;

// ✅ 파라미터로 전달 (Axios가 인코딩 처리)
const response = await api.get('/api/search', {
  params: { q: userInput },
});
```

점검 항목:
- 사용자 입력이 URL, 쿼리, 헤더에 직접 삽입되는 경우
- 폼 입력값의 길이/형식 검증 누락
- 파일 업로드 시 타입/크기 제한 없음
- URL 파라미터(`searchParams`)를 검증 없이 사용

## XSS (Cross-Site Scripting)

```typescript
// ❌ dangerouslySetInnerHTML 무분별 사용
<div dangerouslySetInnerHTML={{ __html: userContent }} />

// ✅ 필요시 DOMPurify로 새니타이징
import DOMPurify from 'dompurify';
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userContent) }} />

// ❌ href에 사용자 입력 직접 삽입
<a href={userProvidedUrl}>링크</a> // javascript: 프로토콜 가능

// ✅ 프로토콜 검증
const isSafeUrl = (url: string) =>
  url.startsWith('https://') || url.startsWith('http://');
```

점검 항목:
- `dangerouslySetInnerHTML` 사용 시 새니타이징 여부
- 사용자 입력이 `href`, `src`, `action` 속성에 직접 삽입되는 경우
- URL에 `javascript:` 프로토콜 허용 여부
- 동적으로 생성된 HTML/스크립트

## 인증 / 인가 결함

```typescript
// ❌ 클라이언트에서만 권한 체크
{user.role === 'admin' && <AdminPanel />}
// AdminPanel의 API 호출은 권한 체크 없음

// ❌ 토큰을 localStorage에 저장 (XSS 시 탈취 가능)
localStorage.setItem('token', accessToken);
```

점검 항목:
- 클라이언트 사이드에서만 권한 검사 (서버 검증 없이 UI만 숨기기)
- 토큰 저장 위치 (localStorage는 XSS에 취약)
- 인증 만료 처리 누락 (토큰 갱신 로직 없음)
- 민감한 API 호출에 인증 헤더 누락

## 민감 데이터 노출

```typescript
// ❌ 콘솔에 민감 정보 출력
console.log('user data:', { email, password, token });

// ❌ 에러 메시지에 내부 정보 노출
catch (error) {
  setError(`DB 연결 실패: ${error.message}`); // 내부 구조 노출
}

// ✅ 사용자에게는 일반적인 메시지
catch (error) {
  setError('일시적인 오류가 발생했습니다');
}
```

점검 항목:
- `console.log`에 비밀번호, 토큰, 개인정보 포함
- 에러 메시지에 서버 내부 구조/경로 노출
- API 응답에서 불필요한 민감 필드 클라이언트 전달
- 소스코드에 하드코딩된 API 키, 비밀번호

## 환경변수 오용

```bash
# ❌ 절대 금지: 비밀값에 NEXT_PUBLIC_ 접두사
NEXT_PUBLIC_DATABASE_URL=postgresql://...
NEXT_PUBLIC_SECRET_KEY=abc123
NEXT_PUBLIC_ADMIN_API_KEY=key-12345

# ✅ 비밀값은 NEXT_PUBLIC_ 없이
DATABASE_URL=postgresql://...
SECRET_KEY=abc123
```

점검 항목:
- `NEXT_PUBLIC_` 접두사가 붙은 환경변수에 비밀값 포함
- `.env` 파일이 `.gitignore`에 포함되지 않은 경우
- 환경변수 미설정 시 기본값으로 프로덕션에 위험한 값 사용
- 클라이언트 번들에 서버 전용 환경변수 포함

## 의존성 위험

점검 항목:
- 알려진 취약점이 있는 패키지 버전 사용
- `package.json`에 `*` 또는 범위가 너무 넓은 버전 지정
- 신뢰할 수 없는 출처의 패키지
- 불필요하게 많은 권한을 요구하는 패키지
