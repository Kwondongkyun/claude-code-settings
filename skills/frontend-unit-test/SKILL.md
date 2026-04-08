---
name: frontend-unit-test
description: HTTP 요청이 없는 순수 함수, 유틸, 커스텀 훅의 단위 테스트 작성 시 사용. Vitest + AAA 패턴, 모킹, renderHook. HTTP 요청이 포함된 API 함수 테스트는 frontend-api-mock-test를 사용.
effort: medium
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# 단위 테스트 규칙 (Vitest)

## 대상

유틸 함수, 커스텀 훅, 순수 로직, 상수/설정 검증

## 파일 네이밍

```
✅ utils/formatPrice.test.ts        (같은 디렉토리)
✅ hooks/useAuth.test.ts             (같은 디렉토리)
✅ features/auth/utils.test.ts       (같은 디렉토리)

❌ __tests__/formatPrice.test.ts     (별도 디렉토리 금지)
❌ utils/formatPrice.spec.ts         (.spec 금지, .test 사용)
```

## 기본 구조 (AAA 패턴)

모든 테스트는 Arrange-Act-Assert 3단계로 작성한다.

```typescript
import { describe, it, expect } from 'vitest'
import { formatPrice } from './formatPrice'

describe('formatPrice', () => {
  it('숫자를 원화 형식으로 변환한다', () => {
    // Arrange
    const price = 1000

    // Act
    const result = formatPrice(price)

    // Assert
    expect(result).toBe('1,000원')
  })

  it('0을 처리한다', () => {
    expect(formatPrice(0)).toBe('0원')
  })

  it('음수를 처리한다', () => {
    expect(formatPrice(-500)).toBe('-500원')
  })
})
```

## 모킹 규칙

```typescript
// ✅ 외부 의존성만 모킹
vi.mock('@/lib/api/axios')
vi.mock('next/navigation')

// ❌ 테스트 대상 자체를 모킹하면 안 됨
vi.mock('./formatPrice')

// ❌ 내부 유틸을 모킹하면 안 됨 (실제 동작을 테스트해야 함)
vi.mock('./utils')
```

### vi.fn() — 스파이 함수

```typescript
const handleSubmit = vi.fn()

// 호출 여부 확인
expect(handleSubmit).toHaveBeenCalled()
expect(handleSubmit).toHaveBeenCalledTimes(1)
expect(handleSubmit).toHaveBeenCalledWith('arg1', 'arg2')

// 반환값 지정
const getId = vi.fn().mockReturnValue('mock-id')
const fetchData = vi.fn().mockResolvedValue({ name: '동균' })
```

### vi.mock() — 모듈 모킹

```typescript
// 모듈 전체 모킹
vi.mock('@/lib/api/axios', () => ({
  api: {
    get: vi.fn(),
    post: vi.fn(),
  },
}))

// 부분 모킹 (나머지는 실제 모듈 사용)
vi.mock('@/lib/utils', async () => {
  const actual = await vi.importActual('@/lib/utils')
  return {
    ...actual,
    generateId: vi.fn().mockReturnValue('mock-id'),
  }
})
```

## Setup / Teardown

```typescript
beforeEach(() => {
  vi.clearAllMocks()  // 필수: 모든 모킹 호출 기록 초기화
})

afterEach(() => {
  vi.restoreAllMocks()  // vi.spyOn 사용 시 원본 복원
})
```

## 커스텀 훅 테스트

```typescript
import { renderHook, act } from '@testing-library/react'
import { useCounter } from './useCounter'

describe('useCounter', () => {
  it('초기값을 설정한다', () => {
    const { result } = renderHook(() => useCounter(10))
    expect(result.current.count).toBe(10)
  })

  it('increment로 값을 증가시킨다', () => {
    const { result } = renderHook(() => useCounter(0))

    act(() => {
      result.current.increment()
    })

    expect(result.current.count).toBe(1)
  })
})
```

### Provider가 필요한 훅

```typescript
// ✅ wrapper로 Provider 감싸기
const wrapper = ({ children }: { children: React.ReactNode }) => (
  <AuthProvider>{children}</AuthProvider>
)

const { result } = renderHook(() => useAuth(), { wrapper })
```

## 비동기 함수 테스트

```typescript
describe('fetchUserName', () => {
  it('사용자 이름을 반환한다', async () => {
    const name = await fetchUserName('user-1')
    expect(name).toBe('동균')
  })

  it('존재하지 않는 사용자면 에러를 던진다', async () => {
    await expect(fetchUserName('invalid')).rejects.toThrow('사용자를 찾을 수 없습니다')
  })
})
```

## 점검 항목

- [ ] 모든 테스트가 AAA 패턴을 따르는가
- [ ] `beforeEach`에서 `vi.clearAllMocks()` 호출하는가
- [ ] 외부 의존성만 모킹하고, 테스트 대상은 실제 코드를 사용하는가
- [ ] 엣지 케이스 (빈 값, 경계값, 에러)를 테스트하는가
- [ ] 각 `it` 블록이 하나의 관심사만 검증하는가
- [ ] 테스트 설명(`it`)이 한국어로 명확하게 동작을 서술하는가
