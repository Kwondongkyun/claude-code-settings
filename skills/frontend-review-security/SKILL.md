---
name: frontend-review-security
description: React/Next.js 코드의 보안 취약점을 리뷰할 때 사용. XSS, 인젝션, 인증 결함, 민감 데이터 노출, 환경변수 오용, 의존성 위험.
effort: medium
allowed-tools: Read, Glob, Grep
---

# 보안 취약점 탐지

## 입력 검증 미비

검증되지 않은 사용자 입력은 URL 인젝션, SQL 인젝션 등으로 악용될 수 있다. 공격자가 URL 파라미터에 악성 쿼리를 삽입하면 서버가 의도하지 않은 동작을 수행한다.

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

innerHTML 계열 API는 HTML 문자열을 그대로 파싱하므로 script 태그까지 실행될 수 있다. 공격자가 사용자 입력에 스크립트를 삽입하면 세션 탈취, 피싱 등이 가능해진다.

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

클라이언트에서만 권한을 체크하면 DevTools로 우회 가능하다. 또한 localStorage에 토큰을 저장하면 XSS 공격 시 토큰이 그대로 탈취된다.

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

`NEXT_PUBLIC_` 접두사가 붙은 환경변수는 클라이언트 번들에 포함되어 누구나 브라우저 DevTools에서 볼 수 있다. 비밀값에 이 접두사를 붙이면 전 세계에 공개하는 것과 같다.

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

## CSRF (Cross-Site Request Forgery)

공격자가 사용자의 인증된 세션을 이용해 의도하지 않은 요청을 보내는 공격. 사용자가 악성 사이트를 방문하는 것만으로 계좌 이체, 비밀번호 변경 등이 실행될 수 있다.

```typescript
// ❌ 쿠키 기반 인증에서 SameSite 미설정
res.setHeader('Set-Cookie', `token=${token}; Path=/`)

// ✅ SameSite + Secure + HttpOnly로 보호
res.setHeader('Set-Cookie',
  `token=${token}; Path=/; HttpOnly; Secure; SameSite=Strict`
)
```

점검 항목:
- 쿠키에 `SameSite=Strict` 또는 `SameSite=Lax` 설정 여부
- 쿠키에 `HttpOnly` 설정 여부 (JavaScript에서 접근 차단)
- 쿠키에 `Secure` 설정 여부 (HTTPS에서만 전송)
- 상태 변경 API(POST/PUT/DELETE)에 CSRF 토큰 검증 여부
- Server Actions 사용 시 Next.js가 자동으로 CSRF 방어하지만, 커스텀 API 라우트는 직접 보호 필요

## CSP (Content Security Policy)

어떤 소스의 스크립트/스타일/이미지를 허용할지 브라우저에게 알려주는 정책. XSS 공격이 성공하더라도 외부 스크립트 실행을 차단할 수 있는 2차 방어선.

```typescript
// next.config.ts
const securityHeaders = [
  {
    key: 'Content-Security-Policy',
    value: [
      "default-src 'self'",
      "script-src 'self' 'nonce-{NONCE}'",  // 인라인 스크립트는 nonce 필요
      "style-src 'self' 'unsafe-inline'",    // TailwindCSS 인라인 스타일 허용
      "img-src 'self' data: https:",
      "font-src 'self' https://fonts.gstatic.com",
      "connect-src 'self' https://api.example.com",
    ].join('; '),
  },
]
```

점검 항목:
- CSP 헤더가 설정되어 있는가
- `script-src 'unsafe-eval'` 사용 여부 (eval 허용은 위험)
- `script-src 'unsafe-inline'` 사용 여부 (인라인 스크립트 허용은 XSS 방어 무력화)
- 외부 CDN 도메인이 허용 목록에 무분별하게 추가되지 않았는가

## CORS (Cross-Origin Resource Sharing)

다른 도메인에서 API를 호출할 수 있는지 제어하는 정책. 잘못 설정하면 아무 사이트에서나 사용자 데이터를 가져갈 수 있다.

```typescript
// ❌ 모든 출처 허용 — 누구나 API 호출 가능
// next.config.ts 또는 API 라우트
headers: { 'Access-Control-Allow-Origin': '*' }

// ✅ 특정 출처만 허용
headers: { 'Access-Control-Allow-Origin': 'https://myapp.com' }
```

점검 항목:
- `Access-Control-Allow-Origin: *`가 프로덕션에서 사용되는가
- credentials(쿠키) 포함 요청에 와일드카드 Origin 사용 여부 (브라우저가 차단하지만, 서버 설정 실수 가능)
- `Access-Control-Allow-Methods`에 불필요한 메서드(DELETE 등) 포함 여부
- preflight 요청(OPTIONS) 처리가 올바른가
