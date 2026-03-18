# DevFeed 프론트엔드 테스트 도입 (Phase 1~2)

## Context

프로젝트에 테스트 파일/의존성/설정이 전혀 없는 상태.
테스트 인프라를 구축하고, 순수 함수(Phase 1) + API 함수(Phase 2) 테스트를 작성한다.
이후 Phase 3~4(Context, 컴포넌트)는 같은 패턴으로 점진적 추가 가능.

## Step 1: 패키지 설치

```bash
npm install -D vitest @testing-library/react @testing-library/jest-dom @testing-library/user-event jsdom vite-tsconfig-paths
```

## Step 2: 설정 파일 생성

### 2-1. `vitest.config.ts` (신규)
- `globals: true`, `environment: 'jsdom'`
- `setupFiles: ['./src/test/setup.ts']`
- `vite-tsconfig-paths` 플러그인 (`@/*` 경로 해석)
- `css: false` (Tailwind 처리 건너뛰어 속도 향상)

### 2-2. `src/test/setup.ts` (신규)
- `@testing-library/jest-dom/vitest` import
- `afterEach`: cleanup, localStorage.clear, vi.restoreAllMocks
- 글로벌 mock: `next/image`, `next/navigation`, `next-themes`, `sonner`, `IntersectionObserver`

### 2-3. `tsconfig.json` (수정)
- `"types": ["vitest/globals"]` 추가

### 2-4. `package.json` (수정)
- scripts에 `test`, `test:watch`, `test:coverage` 추가

## Step 3: 테스트 헬퍼 & 픽스처

### 3-1. `src/test/helpers.tsx` (신규)
- `renderWithProviders()` 함수

### 3-2. `src/test/fixtures/` (신규)
- `article.ts` — `createMockArticle()` 팩토리
- `source.ts` — `createMockSource()` 팩토리
- `user.ts` — `createMockUser()` 팩토리

## Step 4: Phase 1 — 순수 함수 Unit Test

### 4-1. `src/lib/utils.test.ts`
- `formatRelativeTime`: null, invalid, 방금 전, 분/시간/일/월/년 경계값, 미래 시간
- `isSafeUrl`: https, http, javascript:, data:, 빈 문자열, 잘못된 URL
- `cn`: 병합, Tailwind 충돌 해결, 조건부 클래스
- `extractErrorMessage`: Axios 에러, 일반 에러, null

기존 코드 위치: `/Users/kwondong-kyun/Desktop/personal/devfeed/src/lib/utils.ts`

### 4-2. `src/features/feed/categories/constants.test.ts`
- `categoryToSlug`: 매핑된 카테고리 3개, 매핑 안 된 카테고리
- `slugToCategory`: 역매핑, 매핑 안 된 슬러그
- `getSourceIdsForCategory`: 필터링, 빈 배열, 매칭 없는 카테고리

기존 코드 위치: `/Users/kwondong-kyun/Desktop/personal/devfeed/src/features/feed/categories/constants.ts`

## Step 5: Phase 2 — API 함수 Unit Test

Mock 전략: `vi.mock('@/lib/api/axios')` → `api.get/post/delete`를 `vi.fn()`으로 대체

### 5-1. `src/features/feed/articles/api.test.ts`
- `listArticlesApi`: URLSearchParams 빌드 (source, search, cursor, sort, limit 기본값 20)
- `markArticleReadApi`: 올바른 엔드포인트 POST

기존 코드 위치: `/Users/kwondong-kyun/Desktop/personal/devfeed/src/features/feed/articles/api.ts`

### 5-2. `src/features/auth/api.test.ts`
- `loginApi`: 엔드포인트, 요청 데이터, 응답 추출
- `registerApi`: 엔드포인트, 요청 데이터, 응답 추출
- `getMeApi`: GET 요청, 응답에서 User 추출
- `listFavoriteSourcesApi`: GET 요청, string[] 추출
- `addFavoriteSourceApi`: POST, sourceId 경로 파라미터
- `removeFavoriteSourceApi`: DELETE, sourceId 경로 파라미터

기존 코드 위치: `/Users/kwondong-kyun/Desktop/personal/devfeed/src/features/auth/api.ts`

### 5-3. `src/features/feed/sources/api.test.ts`
- `listSourcesApi`: GET 요청, SourceItem[] 추출

기존 코드 위치: `/Users/kwondong-kyun/Desktop/personal/devfeed/src/features/feed/sources/api.ts`

### 5-4. `src/features/feed/cron/api.test.ts`
- `fetchFeedsApi`: POST 요청, FetchFeedsResult 추출

기존 코드 위치: `/Users/kwondong-kyun/Desktop/personal/devfeed/src/features/feed/cron/api.ts`

## 파일 요약

| 유형 | 파일 | 작업 |
|------|------|------|
| 설정 | `vitest.config.ts` | 신규 |
| 설정 | `src/test/setup.ts` | 신규 |
| 설정 | `tsconfig.json` | 수정 (`types` 추가) |
| 설정 | `package.json` | 수정 (deps + scripts) |
| 헬퍼 | `src/test/helpers.tsx` | 신규 |
| 픽스처 | `src/test/fixtures/article.ts` | 신규 |
| 픽스처 | `src/test/fixtures/source.ts` | 신규 |
| 픽스처 | `src/test/fixtures/user.ts` | 신규 |
| 테스트 | `src/lib/utils.test.ts` | 신규 (Phase 1) |
| 테스트 | `src/features/feed/categories/constants.test.ts` | 신규 (Phase 1) |
| 테스트 | `src/features/feed/articles/api.test.ts` | 신규 (Phase 2) |
| 테스트 | `src/features/auth/api.test.ts` | 신규 (Phase 2) |
| 테스트 | `src/features/feed/sources/api.test.ts` | 신규 (Phase 2) |
| 테스트 | `src/features/feed/cron/api.test.ts` | 신규 (Phase 2) |

총 신규 12개, 수정 2개

## 검증

```bash
npm test                 # 전체 테스트 실행 → 모두 통과 확인
npm run test:coverage    # 커버리지 확인
npm run build            # 빌드가 깨지지 않는지 확인
```
