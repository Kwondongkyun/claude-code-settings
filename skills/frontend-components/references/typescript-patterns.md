# 고급 TypeScript 패턴

## Brand Type (명목적 타이핑)

같은 string이지만 의미가 다른 ID를 컴파일 타임에 구분한다. UserId와 ProductId를 실수로 섞어 쓰는 버그를 방지.

```typescript
// 브랜드 타입 헬퍼
type Brand<T, B extends string> = T & { __brand: B }

type UserId = Brand<string, 'UserId'>
type ProductId = Brand<string, 'ProductId'>

// 팩토리 함수
function asUserId(id: string): UserId { return id as UserId }
function asProductId(id: string): ProductId { return id as ProductId }

// 사용
function getUser(id: UserId) { ... }
function getProduct(id: ProductId) { ... }

const userId = asUserId('user-123')
const productId = asProductId('prod-456')

getUser(userId)      // ✅
getUser(productId)   // ❌ 컴파일 에러
```

적용 기준:
- 여러 종류의 ID가 같은 타입(string)인 경우
- API 호출에서 ID를 잘못 전달하면 심각한 버그가 나는 경우
- 2~3종류 이하면 과도. 5종류 이상이면 도입 검토

## Discriminated Union (판별 유니온)

상태를 명확히 분리하여 불가능한 상태 조합을 타입으로 방지한다.

```typescript
// ❌ boolean 조합 — 불가능한 상태가 존재
interface ApiState {
  isLoading: boolean
  isError: boolean
  data?: User
  error?: Error
}
// isLoading: true + isError: true + data: User? 의미 없는 조합

// ✅ Discriminated Union — 유효한 상태만 존재
type ApiState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error }

// 사용할 때 TypeScript가 자동으로 타입 좁혀줌
function renderUser(state: ApiState<User>) {
  switch (state.status) {
    case 'idle':
      return null
    case 'loading':
      return <Skeleton />
    case 'success':
      return <UserCard user={state.data} />  // data가 확실히 존재
    case 'error':
      return <ErrorMessage error={state.error} />  // error가 확실히 존재
  }
}
```

적용 기준:
- 상태가 3개 이상이고 상호 배타적인 경우
- boolean 조합으로 불가능한 상태가 생기는 경우
- API 응답 처리, 폼 상태, 인증 상태 등

## satisfies 연산자

타입을 검증하면서도 리터럴 타입을 보존한다.

```typescript
// ❌ as const는 타입 검증 안 함
const routes = {
  home: '/',
  about: '/about',
  users: '/userss',  // 오타인데 에러 안 남
} as const

// ❌ 타입 어노테이션은 리터럴 타입 소실
const routes: Record<string, string> = {
  home: '/',
  about: '/about',
}
routes.home  // string (리터럴 '/' 아님)

// ✅ satisfies — 검증 + 리터럴 보존
const routes = {
  home: '/',
  about: '/about',
  users: '/userss',  // 검증 규칙에 따라 에러 가능
} satisfies Record<string, string>
routes.home  // '/' (리터럴 타입 보존)
```

적용 기준:
- 설정 객체의 값을 타입으로 검증하면서 자동완성도 유지하고 싶을 때
- Record, Map 같은 키-값 구조에서 값의 타입을 좁히고 싶을 때
