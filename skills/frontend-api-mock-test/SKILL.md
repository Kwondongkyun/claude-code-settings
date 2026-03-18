---
name: frontend-api-mock-test
description: Use when writing API integration tests with MSW. Enforces MSW v2 handlers, setupServer pattern, Axios interceptor testing, and error scenario coverage.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# API 모킹 테스트 규칙 (MSW v2 + Vitest)

## 대상

API 함수, Axios 인터셉터, 에러 핸들링 로직, 비동기 데이터 흐름 검증

## MSW v2 핸들러 패턴

```typescript
// mocks/handlers.ts
import { http, HttpResponse } from 'msw'

export const handlers = [
  // GET 요청
  http.get('/api/v1/members/me', () => {
    return HttpResponse.json({
      success: true,
      result: { id: '1', name: '동균', email: 'test@test.com' },
    })
  }),

  // POST 요청
  http.post('/api/v1/auth/login', async ({ request }) => {
    const body = await request.json()
    if (body.email === 'test@test.com') {
      return HttpResponse.json({
        success: true,
        result: { access_token: 'mock-token', refresh_token: 'mock-refresh' },
      })
    }
    return HttpResponse.json(
      { success: false, message: '인증 실패' },
      { status: 401 }
    )
  }),
]
```

## 서버 설정

```typescript
// mocks/server.ts
import { setupServer } from 'msw/node'
import { handlers } from './handlers'

export const server = setupServer(...handlers)
```

```typescript
// vitest.setup.ts (또는 각 테스트 파일)
import { server } from '@/mocks/server'

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }))
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

```typescript
// ✅ onUnhandledRequest: 'error' — 모킹 안 된 요청을 잡아냄
server.listen({ onUnhandledRequest: 'error' })

// ❌ 기본값(warn)은 모킹 누락을 놓칠 수 있음
server.listen()
```

## API 함수 테스트

```typescript
import { getMeApi } from '@/features/auth/api'
import { server } from '@/mocks/server'
import { http, HttpResponse } from 'msw'

describe('getMeApi', () => {
  it('사용자 정보를 반환한다', async () => {
    const result = await getMeApi()

    expect(result.success).toBe(true)
    expect(result.result.name).toBe('동균')
  })

  it('서버 에러 시 에러를 던진다', async () => {
    // 특정 테스트에서만 핸들러 오버라이드
    server.use(
      http.get('/api/v1/members/me', () => {
        return HttpResponse.json(
          { message: '서버 오류' },
          { status: 500 }
        )
      })
    )

    await expect(getMeApi()).rejects.toThrow()
  })
})
```

## 에러 시나리오 테스트

### 네트워크 에러

```typescript
server.use(
  http.get('/api/v1/members/me', () => {
    return HttpResponse.error()  // 네트워크 에러 시뮬레이션
  })
)
```

### 타임아웃

```typescript
server.use(
  http.get('/api/v1/members/me', async () => {
    await new Promise((resolve) => setTimeout(resolve, 35000))
    return HttpResponse.json({ success: true })
  })
)
```

### HTTP 상태별 에러

```typescript
// 401 Unauthorized
server.use(
  http.get('/api/v1/members/me', () => {
    return HttpResponse.json({ message: '인증 만료' }, { status: 401 })
  })
)

// 404 Not Found
server.use(
  http.get('/api/v1/users/:id', () => {
    return HttpResponse.json({ message: '사용자 없음' }, { status: 404 })
  })
)

// 422 Validation Error
server.use(
  http.post('/api/v1/users', () => {
    return HttpResponse.json(
      { message: '이메일 형식 오류', errors: { email: '유효하지 않은 이메일' } },
      { status: 422 }
    )
  })
)
```

## Axios 인터셉터 테스트

### 401 → Refresh → 재요청 흐름

```typescript
describe('401 refresh 인터셉터', () => {
  it('401 응답 시 토큰을 갱신하고 원래 요청을 재시도한다', async () => {
    let callCount = 0

    server.use(
      // 첫 번째 호출: 401
      http.get('/api/v1/members/me', () => {
        callCount++
        if (callCount === 1) {
          return HttpResponse.json({ message: '만료' }, { status: 401 })
        }
        // 재시도: 성공
        return HttpResponse.json({
          success: true,
          result: { name: '동균' },
        })
      }),
      // refresh 엔드포인트
      http.post('/api/v1/auth/refresh', () => {
        return HttpResponse.json({
          success: true,
          result: { access_token: 'new-token', refresh_token: 'new-refresh' },
        })
      })
    )

    // localStorage 세팅
    localStorage.setItem('access_token', 'expired-token')
    localStorage.setItem('refresh_token', 'valid-refresh')

    const result = await getMeApi()
    expect(result.result.name).toBe('동균')
    expect(localStorage.getItem('access_token')).toBe('new-token')
  })

  it('refresh도 실패하면 토큰을 제거한다', async () => {
    server.use(
      http.get('/api/v1/members/me', () => {
        return HttpResponse.json({ message: '만료' }, { status: 401 })
      }),
      http.post('/api/v1/auth/refresh', () => {
        return HttpResponse.json({ message: '만료' }, { status: 401 })
      })
    )

    localStorage.setItem('access_token', 'expired')
    localStorage.setItem('refresh_token', 'expired')

    await expect(getMeApi()).rejects.toThrow()
    expect(localStorage.getItem('access_token')).toBeNull()
    expect(localStorage.getItem('refresh_token')).toBeNull()
  })
})
```

## 핸들러 오버라이드 규칙

```typescript
// ✅ server.use()로 특정 테스트에서만 오버라이드
server.use(
  http.get('/api/v1/members/me', () => {
    return HttpResponse.json({ message: '에러' }, { status: 500 })
  })
)
// afterEach의 server.resetHandlers()가 원래 핸들러로 복원

// ❌ 전역 handlers를 직접 수정하지 않음
```

## 점검 항목

- [ ] `beforeAll/afterEach/afterAll`에서 서버 생명주기를 관리하는가
- [ ] `onUnhandledRequest: 'error'`로 모킹 누락을 감지하는가
- [ ] 성공/실패/네트워크 에러/타임아웃 시나리오를 모두 테스트하는가
- [ ] `server.use()`로 테스트별 오버라이드하고, 전역 handlers를 수정하지 않는가
- [ ] 인터셉터 로직 (401 refresh) 을 별도 테스트로 검증하는가
- [ ] `frontend-axios` 스킬의 에러 핸들링 3단계를 각각 테스트하는가
