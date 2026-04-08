---
name: frontend-tanstack-query
description: >
  TanStack Query(@tanstack/react-query) 패턴 적용. useQuery, useMutation, 캐시 무효화, 낙관적 업데이트.
  트리거 조건: (1) import에 @tanstack/react-query가 이미 있을 때,
  (2) 클라이언트 컴포넌트에서 useEffect + useState로 API를 호출하는 패턴이 반복될 때 — 이 경우 TanStack Query 도입을 제안,
  (3) 같은 데이터를 여러 컴포넌트에서 각각 fetch하는 중복이 보일 때,
  (4) 캐싱, 백그라운드 갱신, 낙관적 업데이트가 필요한 상황일 때.
effort: medium
allowed-tools: Read, Write, Edit, Glob, Grep
---

# TanStack Query 규칙

## 언제 TanStack Query, 언제 안 쓰나?

| 상황 | 선택 | 이유 |
|------|------|------|
| 서버 데이터 조회 (목록, 상세) | **useQuery** | 캐싱, 백그라운드 갱신, 자동 재시도 |
| 서버 데이터 변경 (생성/수정/삭제) | **useMutation** | 낙관적 업데이트, 에러 롤백 |
| Server Component에서 직접 fetch | **쓰지 않음** | RSC는 서버에서 실행, 캐싱은 Next.js가 담당 |
| 클라이언트 전용 상태 (모달, 탭) | **쓰지 않음** | useState로 충분 |
| 단순 Server Action 폼 제출 | **쓰지 않음** | frontend-server-actions 사용 |

핵심: TanStack Query는 **클라이언트 컴포넌트에서 서버 데이터를 다룰 때** 사용. Server Components에서는 불필요.

## 설정

```typescript
// lib/query/provider.tsx
'use client'

import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'
import { useState } from 'react'

export function QueryProvider({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 60 * 1000,        // 1분간 fresh (재요청 안 함)
            gcTime: 5 * 60 * 1000,       // 5분간 캐시 유지
            retry: 1,                     // 실패 시 1회 재시도
            refetchOnWindowFocus: false,  // 탭 전환 시 자동 갱신 비활성화
          },
        },
      }),
  )

  return (
    <QueryClientProvider client={queryClient}>
      {children}
      {process.env.NODE_ENV === 'development' && <ReactQueryDevtools />}
    </QueryClientProvider>
  )
}
```

```typescript
// app/layout.tsx
import { QueryProvider } from '@/lib/query/provider'

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <QueryProvider>{children}</QueryProvider>
      </body>
    </html>
  )
}
```

### 설정 규칙

1. **QueryClient를 useState로 생성** — 컴포넌트 밖에서 생성하면 서버/클라이언트 간 캐시가 공유되어 데이터 누수 위험
2. **staleTime 설정 필수** — 기본값 0이면 매번 refetch. 적어도 30초~1분 설정
3. **DevTools는 개발 환경에서만** — production 번들에 포함되지 않도록

## useQuery — 데이터 조회

```typescript
// features/user/hooks.ts
import { useQuery } from '@tanstack/react-query'
import { getUsersApi, getUserApi } from './api'

// 목록 조회
export function useUsers() {
  return useQuery({
    queryKey: ['users'],
    queryFn: getUsersApi,
  })
}

// 상세 조회
export function useUser(id: string) {
  return useQuery({
    queryKey: ['users', id],
    queryFn: () => getUserApi(id),
    enabled: !!id,  // id가 없으면 쿼리 실행 안 함
  })
}
```

### queryKey 규칙

queryKey는 캐시의 주소. 잘못 설계하면 데이터가 꼬인다.

```typescript
// 계층적으로 설계 — 상위 키로 일괄 무효화 가능
['users']              // 사용자 목록
['users', id]          // 사용자 상세
['users', id, 'posts'] // 사용자의 게시물

// 필터/페이지네이션은 객체로
['users', { page: 1, status: 'active' }]
```

규칙:
- **엔티티명을 첫 번째 요소로** — `['users']`, `['products']`
- **ID는 두 번째** — `['users', '123']`
- **하위 리소스는 세 번째** — `['users', '123', 'orders']`
- **필터/옵션은 마지막에 객체로** — `['users', { page, sort }]`
- **하드코딩 금지** — queryKey를 상수로 관리

```typescript
// features/user/keys.ts
export const userKeys = {
  all: ['users'] as const,
  lists: () => [...userKeys.all, 'list'] as const,
  list: (filters: UserFilters) => [...userKeys.lists(), filters] as const,
  details: () => [...userKeys.all, 'detail'] as const,
  detail: (id: string) => [...userKeys.details(), id] as const,
}
```

## useMutation — 데이터 변경

```typescript
// features/user/hooks.ts
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { createUserApi, deleteUserApi } from './api'

export function useCreateUser() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: createUserApi,
    onSuccess: () => {
      // 사용자 목록 캐시 무효화 → 자동 refetch
      queryClient.invalidateQueries({ queryKey: ['users'] })
    },
  })
}

export function useDeleteUser() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: deleteUserApi,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] })
    },
  })
}
```

### 사용하는 쪽

```typescript
function CreateUserButton() {
  const { mutate, isPending } = useCreateUser()

  return (
    <Button
      disabled={isPending}
      onClick={() => mutate({ name: '김철수', email: 'test@test.com' })}
    >
      {isPending ? '생성 중...' : '사용자 생성'}
    </Button>
  )
}
```

## 낙관적 업데이트

서버 응답을 기다리지 않고 UI를 먼저 업데이트. 실패 시 이전 상태로 롤백.

```typescript
export function useToggleTodo() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: toggleTodoApi,

    // 요청 전: UI 먼저 업데이트
    onMutate: async (todoId) => {
      // 진행 중인 refetch 취소 (충돌 방지)
      await queryClient.cancelQueries({ queryKey: ['todos'] })

      // 이전 상태 백업 (롤백용)
      const previous = queryClient.getQueryData(['todos'])

      // 캐시 직접 업데이트
      queryClient.setQueryData(['todos'], (old: Todo[]) =>
        old.map((todo) =>
          todo.id === todoId ? { ...todo, completed: !todo.completed } : todo
        ),
      )

      return { previous }  // onError에서 사용
    },

    // 실패 시: 롤백
    onError: (_err, _todoId, context) => {
      queryClient.setQueryData(['todos'], context?.previous)
    },

    // 성공/실패 무관하게: 서버 데이터로 동기화
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['todos'] })
    },
  })
}
```

적용 기준:
- 토글 (좋아요, 완료) — 실패율 낮고 즉각 피드백 중요
- 목록에서 삭제 — 즉시 사라지고 실패 시 복구
- 순서 변경 (드래그) — 서버 응답까지 기다리면 UX 나쁨

## 파일 구조

```
features/[domain]/
├── api.ts          # API 함수 (Axios)
├── hooks.ts        # useQuery/useMutation 훅
├── keys.ts         # queryKey 상수
└── types.ts        # 요청/응답 타입
```

규칙:
- **훅은 features 폴더에** — 컴포넌트와 분리
- **queryKey는 keys.ts에** — 하드코딩 방지
- **API 함수는 api.ts에** — TanStack Query와 Axios를 분리

## 점검 항목

- [ ] QueryClient를 useState로 생성하는가 (컴포넌트 밖 X)
- [ ] staleTime이 설정되어 있는가 (기본값 0은 매번 refetch)
- [ ] queryKey가 계층적으로 설계되어 있는가
- [ ] queryKey를 하드코딩하지 않고 상수(keys.ts)로 관리하는가
- [ ] mutation 성공 후 관련 쿼리를 invalidateQueries하는가
- [ ] 낙관적 업데이트 시 onError에서 롤백하는가
- [ ] 낙관적 업데이트 시 onSettled에서 invalidateQueries하는가
- [ ] enabled 옵션으로 불필요한 쿼리 실행을 방지하는가
