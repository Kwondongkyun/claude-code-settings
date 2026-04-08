---
name: frontend-server-actions
description: Server Actions로 데이터 변경(생성/수정/삭제)을 구현할 때 사용. 폼 제출, 캐시 무효화, useFormStatus/useOptimistic 패턴 적용. "use server" 함수, revalidatePath, Server Action 관련 작업에 반드시 사용.
effort: medium
allowed-tools: Read, Write, Edit, Glob, Grep
---

# Server Actions 규칙

## 언제 Server Actions, 언제 RHF + Axios?

판단 기준은 **폼의 복잡도**다.

| 상황 | 선택 | 이유 |
|------|------|------|
| 단순 CRUD (1~3 필드, 간단한 검증) | **Server Actions** | API 라우트 불필요, 코드 적음 |
| 복잡한 폼 (5+ 필드, 실시간 검증, 다단계) | **RHF + Zod** | 클라이언트 검증, 필드 상태 관리 필요 |
| 파일 업로드 + 프로그레스 | **Axios** | 업로드 진행률 추적 필요 |
| 낙관적 업데이트 필요 | **Server Actions + useOptimistic** | 네이티브 지원 |
| JavaScript 비활성화에서도 동작 필요 | **Server Actions** | Progressive Enhancement |

## Server Action 작성 규칙

### 파일 구조

```
features/[domain]/
├── actions.ts        # Server Actions (반드시 별도 파일)
├── types.ts          # 요청/응답 타입
└── hooks.ts          # 클라이언트 훅 (useOptimistic 등)
```

Server Actions는 컴포넌트 파일에 인라인으로 넣지 않는다. 테스트와 재사용이 어려워지기 때문.

### 기본 패턴

```typescript
// features/user/actions.ts
'use server'

import { revalidatePath } from 'next/cache'
import { z } from 'zod'

const CreateUserSchema = z.object({
  name: z.string().min(1, '이름을 입력하세요'),
  email: z.string().email('올바른 이메일 형식이 아닙니다'),
})

// 반환 타입을 명시하여 클라이언트에서 에러 처리 가능하게
type ActionResult = {
  success: boolean
  error?: string
  fieldErrors?: Record<string, string[]>
}

export async function createUser(formData: FormData): Promise<ActionResult> {
  const parsed = CreateUserSchema.safeParse({
    name: formData.get('name'),
    email: formData.get('email'),
  })

  if (!parsed.success) {
    return {
      success: false,
      fieldErrors: parsed.error.flatten().fieldErrors,
    }
  }

  try {
    await db.user.create({ data: parsed.data })
    revalidatePath('/users')
    return { success: true }
  } catch (error) {
    return { success: false, error: '사용자 생성에 실패했습니다' }
  }
}
```

### 핵심 규칙

1. **'use server'는 파일 최상단에** — 함수 단위가 아니라 파일 단위로 선언. 해당 파일의 모든 export가 Server Action이 된다.

2. **Zod로 서버에서 반드시 재검증** — 클라이언트 검증은 UX용이고, 서버 검증이 진짜 보안 경계. FormData는 누구나 조작 가능하다.

3. **에러를 throw하지 않고 반환** — throw하면 클라이언트에서 에러 페이지로 이동. ActionResult 객체로 반환해야 UI에서 인라인 에러 표시 가능.

4. **revalidatePath/revalidateTag로 캐시 무효화** — 데이터 변경 후 관련 페이지를 갱신해야 사용자가 최신 데이터를 본다.

## useFormStatus — 로딩 상태

Server Action 실행 중인지 자동으로 감지한다. 폼의 자식 컴포넌트에서만 동작.

```typescript
// components/SubmitButton/index.tsx
'use client'

import { useFormStatus } from 'react-dom'

export function SubmitButton({ children = '저장' }: { children?: string }) {
  const { pending } = useFormStatus()

  return (
    <button type="submit" disabled={pending}>
      {pending ? '처리 중...' : children}
    </button>
  )
}
```

```typescript
// 사용하는 쪽
import { createUser } from '@/features/user/actions'
import { SubmitButton } from '@/components/SubmitButton'

export default function CreateUserPage() {
  return (
    <form action={createUser}>
      <input name="name" required />
      <input name="email" type="email" required />
      <SubmitButton>사용자 생성</SubmitButton>
    </form>
  )
}
```

주의: `useFormStatus`는 **form의 자식 컴포넌트**에서만 동작한다. form과 같은 레벨에서 호출하면 pending이 항상 false.

```typescript
// ❌ form과 같은 레벨 — pending 감지 안됨
function Page() {
  const { pending } = useFormStatus()
  return <form action={action}><button disabled={pending}>저장</button></form>
}

// ✅ form의 자식 컴포넌트로 분리
function Page() {
  return <form action={action}><SubmitButton /></form>
}
```

## useActionState — 서버 응답 처리

Server Action의 반환값을 상태로 관리한다. 에러 메시지, 필드 에러 등을 UI에 표시할 때 사용.

```typescript
'use client'

import { useActionState } from 'react'
import { createUser } from '@/features/user/actions'
import { SubmitButton } from '@/components/SubmitButton'

export function CreateUserForm() {
  const [state, formAction] = useActionState(createUser, {
    success: false,
    error: undefined,
    fieldErrors: undefined,
  })

  return (
    <form action={formAction}>
      <div>
        <input name="name" required />
        {state.fieldErrors?.name && (
          <p className="text-red-500 text-sm">{state.fieldErrors.name[0]}</p>
        )}
      </div>
      <div>
        <input name="email" type="email" required />
        {state.fieldErrors?.email && (
          <p className="text-red-500 text-sm">{state.fieldErrors.email[0]}</p>
        )}
      </div>
      {state.error && <p className="text-red-500">{state.error}</p>}
      <SubmitButton />
    </form>
  )
}
```

## useOptimistic — 낙관적 업데이트

서버 응답을 기다리지 않고 UI를 먼저 업데이트한다. 사용자 체감 속도가 빨라진다.

```typescript
'use client'

import { useOptimistic } from 'react'
import { toggleTodo } from '@/features/todo/actions'
import type { Todo } from '@/features/todo/types'

export function TodoList({ todos }: { todos: Todo[] }) {
  const [optimisticTodos, addOptimistic] = useOptimistic(
    todos,
    (state, updatedId: number) =>
      state.map((todo) =>
        todo.id === updatedId ? { ...todo, completed: !todo.completed } : todo
      ),
  )

  return (
    <ul>
      {optimisticTodos.map((todo) => (
        <li key={todo.id}>
          <form
            action={async () => {
              addOptimistic(todo.id)      // UI 먼저 업데이트
              await toggleTodo(todo.id)   // 서버에 반영
            }}
          >
            <button type="submit">
              {todo.completed ? '✓' : '○'} {todo.text}
            </button>
          </form>
        </li>
      ))}
    </ul>
  )
}
```

적용 기준:
- 토글 (좋아요, 완료 체크, 즐겨찾기) — 실패 확률 낮고 즉각 피드백 중요
- 목록에서 항목 삭제 — 즉시 사라지고, 실패 시 복구
- 댓글 추가 — 작성 즉시 보이고, 서버 저장은 백그라운드

## 캐시 무효화

데이터 변경 후 어떤 범위를 갱신할지 결정한다.

```typescript
import { revalidatePath, revalidateTag } from 'next/cache'

// 특정 경로의 캐시 무효화
revalidatePath('/users')          // /users 페이지만
revalidatePath('/users', 'layout') // /users 하위 전체

// 태그 기반 무효화 (더 세밀한 제어)
revalidateTag('users')

// fetch에서 태그 지정
fetch('/api/users', { next: { tags: ['users'] } })
```

선택 기준:
- **revalidatePath**: 특정 페이지를 갱신할 때. 간단하지만 범위가 넓음
- **revalidateTag**: 특정 데이터만 갱신할 때. 정밀하지만 태그 설계 필요

## 보안 주의사항

Server Actions는 HTTP 엔드포인트로 노출된다. 누구나 직접 호출할 수 있으므로:

1. **인증 확인 필수** — 모든 Server Action 시작에서 세션/토큰 확인
```typescript
'use server'

export async function deleteUser(id: string) {
  const session = await getSession()
  if (!session) throw new Error('Unauthorized')
  if (session.role !== 'admin') throw new Error('Forbidden')

  await db.user.delete({ where: { id } })
  revalidatePath('/users')
}
```

2. **입력값 재검증 필수** — FormData는 클라이언트에서 조작 가능. Zod로 서버에서 반드시 다시 검증

3. **rate limiting 고려** — Server Action도 API처럼 남용될 수 있음

## 점검 항목

- [ ] 'use server'가 파일 최상단에 있는가 (함수 단위 아님)
- [ ] Server Action이 별도 파일(actions.ts)에 분리되어 있는가
- [ ] FormData를 Zod로 서버에서 재검증하는가
- [ ] 에러를 throw하지 않고 ActionResult로 반환하는가
- [ ] 데이터 변경 후 revalidatePath/revalidateTag를 호출하는가
- [ ] 인증/권한 확인이 Action 시작에 있는가
- [ ] useFormStatus가 form의 자식 컴포넌트에서 호출되는가
