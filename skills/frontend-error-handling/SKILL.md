---
name: frontend-error-handling
description: 에러 처리 전략을 구현할 때 사용. Error Boundary, error.tsx, not-found.tsx, global-error.tsx, 에러 로깅, 사용자 친화적 에러 UI. 렌더링 에러, 404, 500 에러 페이지 관련 작업에 반드시 사용.
effort: medium
allowed-tools: Read, Write, Edit, Glob, Grep
---

# 에러 처리 전략

## 에러 처리의 3계층

각 계층이 다른 종류의 에러를 담당한다. 모든 계층이 있어야 사용자가 흰 화면을 보지 않는다.

| 계층 | 담당 | 도구 | 현재 스킬 |
|------|------|------|----------|
| **API 에러** | 네트워크 실패, 401, 500 | Axios 인터셉터 | frontend-axios ✅ |
| **폼 에러** | 입력 검증, 제출 실패 | RHF + Zod / Server Actions | frontend-form ✅ |
| **렌더링 에러** | 컴포넌트 크래시, 데이터 null | Error Boundary | **이 스킬** |

## Next.js App Router 에러 파일 구조

```
app/
├── error.tsx          # 라우트 세그먼트별 에러 처리
├── not-found.tsx      # 404 페이지
├── global-error.tsx   # 루트 레이아웃 에러 (최후의 안전망)
├── loading.tsx        # 로딩 UI (Suspense 경계)
├── layout.tsx
└── [feature]/
    ├── error.tsx      # 이 기능 전용 에러 처리
    ├── not-found.tsx  # 이 기능 전용 404
    └── page.tsx
```

## error.tsx — 라우트별 에러 처리

Next.js가 자동으로 Error Boundary로 감싸준다. `'use client'`가 필수.

```typescript
// app/error.tsx
'use client'

interface ErrorProps {
  error: Error & { digest?: string }
  reset: () => void
}

export default function Error({ error, reset }: ErrorProps) {
  // 에러 로깅 (프로덕션에서는 외부 서비스로)
  useEffect(() => {
    console.error('Unhandled error:', error)
  }, [error])

  return (
    <div className="flex flex-col items-center justify-center min-h-[400px] gap-4">
      <h2 className="text-xl font-semibold">문제가 발생했습니다</h2>
      <p className="text-muted-foreground">
        일시적인 오류입니다. 다시 시도해주세요.
      </p>
      <Button onClick={reset}>다시 시도</Button>
    </div>
  )
}
```

### 핵심 규칙

1. **`'use client'` 필수** — Error Boundary는 클라이언트에서만 동작한다.

2. **`reset` 함수 제공** — 사용자가 "다시 시도" 버튼을 누르면 해당 세그먼트를 다시 렌더링. 전체 페이지 새로고침이 아니라 에러 난 부분만 복구.

3. **사용자에게 기술 정보 노출 금지** — `error.message`를 그대로 보여주지 마라. "문제가 발생했습니다" 같은 일반 메시지 + "다시 시도" 버튼이면 충분.

4. **`error.digest`** — 서버에서 발생한 에러의 고유 ID. 사용자에게는 "오류 코드: {digest}"로 보여주고, 로그에서 이 ID로 추적.

## not-found.tsx — 404 페이지

```typescript
// app/not-found.tsx
import Link from 'next/link'

export default function NotFound() {
  return (
    <div className="flex flex-col items-center justify-center min-h-[400px] gap-4">
      <h2 className="text-xl font-semibold">페이지를 찾을 수 없습니다</h2>
      <p className="text-muted-foreground">
        요청하신 페이지가 존재하지 않거나 이동되었습니다.
      </p>
      <Link href="/">
        <Button>홈으로 돌아가기</Button>
      </Link>
    </div>
  )
}
```

### 프로그래밍 방식 404 트리거

동적 라우트에서 데이터가 없을 때:

```typescript
// app/users/[id]/page.tsx
import { notFound } from 'next/navigation'

export default async function UserPage({ params }: { params: { id: string } }) {
  const user = await getUser(params.id)

  if (!user) {
    notFound()  // 가장 가까운 not-found.tsx 렌더링
  }

  return <UserProfile user={user} />
}
```

`notFound()`는 가장 가까운 `not-found.tsx`를 찾아서 렌더링한다. 없으면 Next.js 기본 404.

## global-error.tsx — 최후의 안전망

루트 `layout.tsx`에서 에러가 나면 일반 `error.tsx`로는 잡을 수 없다. `global-error.tsx`가 루트 레이아웃을 대체한다.

```typescript
// app/global-error.tsx
'use client'

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  return (
    // html, body 태그 필수 — 루트 레이아웃을 완전히 대체하므로
    <html>
      <body>
        <div className="flex flex-col items-center justify-center min-h-screen gap-4">
          <h2 className="text-xl font-semibold">심각한 오류가 발생했습니다</h2>
          <button onClick={reset}>다시 시도</button>
        </div>
      </body>
    </html>
  )
}
```

`<html>`과 `<body>` 태그를 직접 포함해야 한다. 루트 레이아웃이 죽었으므로 이 파일이 전체 문서 구조를 제공.

## 기능별 error.tsx 전략

모든 라우트에 같은 에러 페이지를 쓰지 마라. 기능 맥락에 맞는 에러 UI를 제공한다.

```typescript
// app/dashboard/error.tsx — 대시보드 전용
'use client'

export default function DashboardError({ error, reset }: ErrorProps) {
  return (
    <div className="p-6">
      <h2>대시보드를 불러올 수 없습니다</h2>
      <p>데이터 로딩 중 문제가 발생했습니다.</p>
      <div className="flex gap-2">
        <Button onClick={reset}>다시 시도</Button>
        <Link href="/"><Button variant="outline">홈으로</Button></Link>
      </div>
    </div>
  )
}

// app/checkout/error.tsx — 결제 전용
'use client'

export default function CheckoutError({ error, reset }: ErrorProps) {
  return (
    <div className="p-6">
      <h2>결제 처리 중 문제가 발생했습니다</h2>
      <p>결제가 완료되지 않았습니다. 카드 내역을 확인해주세요.</p>
      <div className="flex gap-2">
        <Button onClick={reset}>다시 시도</Button>
        <Link href="/support"><Button variant="outline">고객센터</Button></Link>
      </div>
    </div>
  )
}
```

## 에러 메시지 작성 규칙

| 원칙 | 좋은 예 | 나쁜 예 |
|------|---------|---------|
| 문제를 명확히 | "대시보드를 불러올 수 없습니다" | "오류가 발생했습니다" |
| 해결 방법 제시 | "다시 시도하거나 고객센터에 문의하세요" | (버튼 없음) |
| 기술 정보 숨김 | "일시적인 오류입니다" | "TypeError: Cannot read properties of null" |
| 사용자 탓 안 함 | "결제가 완료되지 않았습니다" | "잘못된 요청입니다" |

## Suspense + Loading 연계

에러 처리와 로딩 처리는 짝이다. Suspense 경계 안에서 데이터를 로드하면 loading.tsx → 성공 시 page.tsx, 실패 시 error.tsx.

```
app/users/
├── loading.tsx    # 데이터 로딩 중 표시
├── error.tsx      # 로딩 실패 시 표시
├── not-found.tsx  # 사용자 없을 때 표시
└── page.tsx       # 성공 시 표시
```

```typescript
// app/users/loading.tsx
import { Skeleton } from '@/components/ui/skeleton'

export default function UsersLoading() {
  return (
    <div className="space-y-4">
      <Skeleton className="h-8 w-48" />
      <Skeleton className="h-64 w-full" />
    </div>
  )
}
```

## 점검 항목

- [ ] `app/error.tsx`가 존재하는가 (최소한 루트 레벨)
- [ ] `app/not-found.tsx`가 존재하는가
- [ ] `app/global-error.tsx`가 존재하는가
- [ ] error.tsx에 `'use client'`가 있는가
- [ ] error.tsx에 `reset` 버튼이 있는가
- [ ] 에러 메시지에 기술 정보가 노출되지 않는가
- [ ] 동적 라우트에서 데이터 없을 때 `notFound()` 호출하는가
- [ ] 에러 발생 시 로깅하는가 (useEffect 내)
- [ ] 주요 기능별 전용 error.tsx가 있는가 (결제, 대시보드 등)
- [ ] loading.tsx와 error.tsx가 짝으로 있는가
