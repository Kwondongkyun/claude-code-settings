---
name: frontend-structure
description: Next.js App Router 프로젝트 구조 설정 시 사용. app(페이지), components(UI), features(도메인), lib(유틸), hooks 폴더 구조.
effort: low
allowed-tools: Read, Glob, Bash(mkdir *)
---

# 프로젝트 구조

## 기본 구조
```
src/
├── app/                    # Next.js App Router 페이지
│   ├── page.tsx           # 메인 홈
│   ├── layout.tsx         # 루트 레이아웃
│   ├── (main)/            # 메인 레이아웃 그룹
│   │   └── [feature]/     # 기능별 페이지
│   │       └── page.tsx
│   └── (auth)/            # 인증 레이아웃 그룹
│
├── components/            # 공통 컴포넌트
│   ├── ui/               # Shadcn/Radix 기본 컴포넌트
│   └── [domain]/         # 도메인별 컴포넌트
│       └── [Component]/  # 디렉토리/index.tsx 패턴
│           └── index.tsx
│
├── features/             # 도메인 모듈 (API + 관련 로직)
│   ├── [domain]/
│   │   └── [feature]/
│   │       ├── api.ts   # API 함수
│   │       └── types.ts # 요청/응답 타입
│   └── shared/
│       └── response.ts  # 공통 응답 타입
│
├── lib/                  # 유틸리티 & 핵심 설정
│   ├── api/
│   │   └── axios.ts     # Axios 인스턴스
│   └── utils.ts         # cn() 등
│
└── hooks/                # 전역 공통 훅
    └── use-mobile.ts
```

## Features 폴더 규칙

**features는 도메인별 로직을 포함하는 모듈 단위**
- ✅ api.ts - API 함수
- ✅ types.ts - 요청/응답 타입
- ✅ schemas.ts - Zod 폼 스키마 + 추출 타입
- ✅ hooks.ts - 도메인 전용 훅 (useAuth 등)
- ✅ Context.tsx - 도메인 전용 Context (AuthContext 등)
- ✅ constants.ts - 도메인 전용 상수
- ❌ 컴포넌트 (components 폴더로)

**hooks/ 폴더**: UI 관련 전역 공통 훅만 (use-mobile 등)

## Features 계층 구조 예시
```
features/
├── auth/
│   ├── api.ts             # API 함수
│   ├── types.ts           # 타입
│   ├── schemas.ts         # Zod 폼 스키마
│   ├── AuthContext.tsx     # Context + Provider
│   └── hooks.ts           # useAuth 등
│
├── feed/
│   ├── articles/
│   │   ├── api.ts
│   │   └── types.ts
│   ├── sources/
│   │   ├── api.ts
│   │   └── types.ts
│   └── categories/
│       └── constants.ts   # 카테고리 상수
│
└── shared/
    └── response.ts        # BaseResponse 등
```

## App Router 특수 파일

app/ 폴더 안에서 Next.js가 자동으로 인식하는 파일들:

| 파일 | 역할 | 필수 |
|------|------|------|
| `page.tsx` | 페이지 컴포넌트 | 해당 라우트에 필수 |
| `layout.tsx` | 공유 레이아웃 (하위 모든 페이지) | 루트에 필수 |
| `loading.tsx` | 로딩 UI (Suspense 경계) | 권장 |
| `error.tsx` | 에러 UI (Error Boundary) | 권장 |
| `not-found.tsx` | 404 페이지 | 루트에 필수 |
| `route.ts` | API Route Handler | API 필요 시 |

### 동적 라우팅

```
app/
├── users/
│   ├── page.tsx              # /users (목록)
│   └── [id]/
│       └── page.tsx          # /users/123 (상세)
├── blog/
│   └── [...slug]/
│       └── page.tsx          # /blog/a/b/c (Catch-all)
└── (marketing)/              # Route Group (URL에 안 나옴)
    ├── about/page.tsx        # /about
    └── contact/page.tsx      # /contact
```

규칙:
- `[id]` — 동적 세그먼트. `params.id`로 접근
- `[...slug]` — Catch-all. `params.slug`는 배열
- `(group)` — Route Group. URL 경로에 포함 안 됨. 레이아웃 공유용

### Metadata

```typescript
// 정적 메타데이터 — 변하지 않는 페이지
export const metadata: Metadata = {
  title: '사용자 목록',
  description: '등록된 사용자를 관리합니다',
}

// 동적 메타데이터 — 데이터에 따라 달라지는 페이지
export async function generateMetadata({ params }): Promise<Metadata> {
  const user = await getUser(params.id)
  return {
    title: user.name,
    description: `${user.name}의 프로필`,
    openGraph: { images: [user.avatar] },
  }
}
```

규칙:
- 모든 page.tsx에 metadata 또는 generateMetadata 중 하나 필수
- OG 이미지는 가능하면 항상 포함 (SNS 공유 시 필요)

### Route Handler (API)

```
app/api/
└── users/
    ├── route.ts              # GET /api/users, POST /api/users
    └── [id]/
        └── route.ts          # GET/PUT/DELETE /api/users/123
```

```typescript
// app/api/users/route.ts
export async function GET() {
  const users = await db.user.findMany()
  return Response.json(users)
}

export async function POST(request: Request) {
  const body = await request.json()
  const user = await db.user.create({ data: body })
  return Response.json(user, { status: 201 })
}
```

규칙:
- Server Actions로 충분한 경우 Route Handler 불필요 (frontend-server-actions 참고)
- 외부 서비스 웹훅, 파일 다운로드 등 Server Actions로 안 되는 경우에만 사용
- `page.tsx`와 같은 폴더에 `route.ts`를 두면 충돌 — 별도 `api/` 폴더 사용

## 컴포넌트와 API 연결
```
페이지: app/(main)/admin/accounts/page.tsx
    ↓ 사용
컴포넌트: components/admin/accounts/AdminTable/index.tsx
    ↓ 호출
API: features/admin/accounts/api.ts
```
