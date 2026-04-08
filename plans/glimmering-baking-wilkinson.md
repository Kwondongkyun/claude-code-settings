# /admin 경로 제거 — 루트(/) 기반 라우팅으로 전환

## Context

nxtcloud-admin은 독립된 admin 전용 Next.js 앱(port 3001)이라 `/admin` prefix가 불필요하다.
`/admin/press/articles` → `/press/articles` 처럼 모든 경로를 루트 기반으로 단순화한다.

## 접근 방식: Route Group `(admin)` 활용

`/login`은 사이드바 없이, 나머지 모든 경로는 사이드바 포함 레이아웃을 적용해야 한다.
Next.js Route Group으로 레이아웃을 분리한다.

```
src/app/
├── layout.tsx              # 루트 레이아웃 (Toaster만, 변경 없음)
├── (admin)/                # 사이드바 적용 그룹 (URL에 영향 없음)
│   ├── layout.tsx          # ← admin/layout.tsx 이동
│   ├── page.tsx            # / (대시보드) ← admin/page.tsx 이동
│   ├── press/
│   │   ├── articles/       # ← admin/press/articles/ 이동
│   │   └── videos/         # ← admin/press/videos/ 이동
│   ├── insights/           # ← admin/insights/ 이동
│   └── metrics/            # ← admin/metrics/ 이동
└── login/
    └── page.tsx            # 변경 없음
```

## 변경 파일 목록

### 1. 디렉토리 이동 (파일 내용 변경 없음)
- `src/app/admin/layout.tsx` → `src/app/(admin)/layout.tsx`
- `src/app/admin/page.tsx` → `src/app/(admin)/page.tsx`
- `src/app/admin/press/` → `src/app/(admin)/press/`
- `src/app/admin/insights/` → `src/app/(admin)/insights/`
- `src/app/admin/metrics/` → `src/app/(admin)/metrics/`
- `src/app/page.tsx` — `/login` redirect 제거, 대신 `/` = 대시보드이므로 삭제 또는 내용 변경 불필요

### 2. href 링크 수정 (전체 `/admin` → `` 치환)
- `src/components/layout/AdminSidebar.tsx` — NAV_ITEMS href
- `src/components/auth/LoginForm.tsx` — 로그인 후 redirect `/admin` → `/`
- `src/components/admin/InsightForm.tsx` — 저장 후 redirect
- `src/components/admin/PressArticleForm.tsx` — 저장 후 redirect
- `src/components/admin/PressVideoForm.tsx` — 저장 후 redirect
- `src/components/admin/MetricsClient.tsx` — 링크
- `src/app/(admin)/page.tsx` (구 admin/page.tsx) — edit 링크들
- `src/app/(admin)/press/articles/PressArticleList.tsx` — editBasePath
- `src/app/(admin)/press/videos/PressVideoList.tsx` — editBasePath
- `src/app/(admin)/insights/InsightsList.tsx` — editBasePath

### 3. Middleware 수정
- `src/middleware.ts` — matcher를 `/admin/:path*` → `/((?!login|_next|favicon).*)` 로 변경
- `src/lib/supabase/middleware.ts` — 보호 경로 조건 `/admin` → `/login` 제외 전체

## 검증
1. `npm run build` 성공
2. `localhost:3001/` → 대시보드 렌더링
3. `localhost:3001/login` → 로그인 페이지 (사이드바 없음)
4. 미인증 상태로 `/` 접근 → `/login` 리다이렉트
5. 각 관리 페이지 (`/press/articles`, `/insights` 등) 정상 접속
