# 피드 UI 리디자인 — A/B 비교 구현

## Context
서비스명 "DevFeed"는 피드(콘텐츠가 연속적으로 흘러가는 목록)를 의미하지만, 현재 UI는 넷플릭스 스타일 가로 캐러셀이다.
두 가지 대안을 `/feed/a`, `/feed/b`에 각각 구현하여 비교 후 메인 홈으로 채택할 수 있도록 한다.
기존 `/` (캐러셀 홈)은 그대로 유지.

---

## A안: 통합 피드 (탭 + 무한스크롤)

전체 카테고리를 가로 탭으로 나열, 선택한 카테고리의 글을 세로 리스트로 무한스크롤.
- 탭: `전체` | `개발자 커뮤니티` | `AI 기업 블로그` | `한국 테크 블로그`
- `전체` 탭은 source 파라미터 없이 API 호출 → 모든 글
- 리스트/카드 전환 버튼

## B안: 투 컬럼 피드 (사이드바 + 피드)

데스크톱: 왼쪽 2/3 메인 피드 + 오른쪽 1/3 사이드바 (인기글, 소스 필터)
모바일: 탭 전환 방식으로 폴백 (A안과 동일한 탭 사용)

---

## 공유 코드 (두 안 모두 사용)

### 1. `useArticleFeed` 커스텀 훅
**파일:** `src/hooks/useArticleFeed.ts` (신규)

카테고리 페이지(`src/app/category/[slug]/page.tsx:127-166`)의 무한스크롤 로직을 추출.

```typescript
interface UseArticleFeedParams {
  sourceIds?: string[];      // 빈 배열 or undefined → 전체 글
  search?: string;
  sort?: "latest" | "oldest";
  pageSize?: number;
}

interface UseArticleFeedReturn {
  articles: ArticleItem[];
  loading: boolean;
  initialLoading: boolean;
  hasMore: boolean;
  observerRef: React.RefObject<HTMLDivElement | null>;
  handleArticleRead: (articleId: number, isRead: boolean) => void;
  displayArticles: (sortKey: SortKey) => ArticleItem[];
}
```

핵심 차이: 기존 카테고리 페이지는 `sourceIds.length === 0`이면 fetch를 skip하지만,
이 훅에서는 `sourceIds`가 undefined이면 source 파라미터 없이 호출 (= 전체 글).

**재사용할 기존 코드:**
- `listArticlesApi()` — `src/features/feed/articles/api.ts:12-28`
- IntersectionObserver + AbortController 패턴 — `src/app/category/[slug]/page.tsx:168-200`

### 2. `useBookmarks` 커스텀 훅
**파일:** `src/hooks/useBookmarks.ts` (신규)

홈(`src/app/page.tsx:77-117`)과 카테고리 페이지(`src/app/category/[slug]/page.tsx:96-125`)에서 중복되는 북마크 로직 추출.

```typescript
interface UseBookmarksReturn {
  bookmarkedIds: Set<number>;
  handleBookmarkToggle: (articleId: number) => void;
}
```

**재사용할 기존 코드:**
- `listBookmarksApi`, `addBookmarkApi`, `removeBookmarkApi` — `src/features/auth/api.ts`
- optimistic update 패턴 — `src/app/page.tsx:93-117`

### 3. `FeedTabs` 컴포넌트
**파일:** `src/components/feed/FeedTabs/index.tsx` (신규)

```typescript
interface FeedTabsProps {
  activeCategory: string | null;  // null = "전체"
  onChange: (category: string | null) => void;
}
```

- 탭 목록: `[null, ...CATEGORY_ORDER]` → `["전체", "개발자 커뮤니티", "AI 기업 블로그", "한국 테크 블로그"]`
- 활성 탭에 `border-b-2 border-orange` 스타일
- 가로 스크롤 가능 (모바일 대응)
- **재사용:** `CATEGORY_ORDER` — `src/features/feed/categories/constants.ts:3-7`

### 4. `FeedLayoutSwitcher` 컴포넌트
**파일:** `src/components/feed/FeedLayoutSwitcher/index.tsx` (신규)

```typescript
interface FeedLayoutSwitcherProps {
  layout: "list" | "card";
  onChange: (layout: "list" | "card") => void;
}
```

- 리스트/카드 아이콘 토글 버튼
- `lucide-react`의 `List`, `LayoutGrid` 아이콘

---

## A안 페이지

**파일:** `src/app/feed/a/page.tsx` (신규)

구조:
```
Header
SearchBar (재사용: src/components/feed/SearchBar)
FeedTabs  (공유 컴포넌트)
SortToggle + FeedLayoutSwitcher (한 줄)
ArticleCard 리스트 (layout="row" or "card", 무한스크롤)
ArticlePreview (재사용: src/components/feed/ArticlePreview)
```

- 탭 변경 시: 해당 카테고리의 sourceIds → `useArticleFeed`에 전달
- `전체` 탭: sourceIds를 undefined로 → 모든 글 fetch
- sourceIds 계산: `getSourceIdsForCategory()` + `listSourcesApi()` (기존 패턴)
- 카드 레이아웃: `grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3`
- 리스트 레이아웃: `flex flex-col gap-[1px] rounded-[16px]` (카테고리 페이지와 동일)

---

## B안 페이지

**파일:** `src/app/feed/b/page.tsx` (신규)

데스크톱 구조 (lg 이상):
```
Header
SearchBar
┌─────────────────────┬──────────────┐
│  SortToggle + Tab   │  인기 글     │
│  ArticleCard 리스트  │  소스 필터   │
│  (2/3 너비)          │  (1/3 너비)  │
└─────────────────────┴──────────────┘
ArticlePreview
```

모바일 구조 (lg 미만):
```
Header
SearchBar
FeedTabs
SortToggle
ArticleCard 리스트
ArticlePreview
```

### FeedSidebar 컴포넌트
**파일:** `src/components/feed/FeedSidebar/index.tsx` (신규)

```typescript
interface FeedSidebarProps {
  sources: SourceItem[];
  activeSourceId: string | null;
  onSourceFilter: (sourceId: string | null) => void;
  onArticleClick?: (article: ArticleItem) => void;
}
```

- 인기글: `PopularRanking` 재사용 — `src/components/feed/PopularRanking/index.tsx`
- 소스 필터: `SourceFilterChips` 재사용 — `src/components/feed/SourceFilterChips/index.tsx`
  (세로 배치로 스타일 변경 → `flex-col` 래퍼)
- `sticky top-20` 으로 스크롤 시 고정

레이아웃:
```
<div className="flex gap-6">
  <div className="flex-1 min-w-0 lg:max-w-[66%]"> ... feed ... </div>
  <aside className="hidden lg:block w-80 shrink-0"> <FeedSidebar /> </aside>
</div>
```

---

## 파일 요약

| 구분 | 파일 |
|------|------|
| 신규 | `src/hooks/useArticleFeed.ts` |
| 신규 | `src/hooks/useBookmarks.ts` |
| 신규 | `src/components/feed/FeedTabs/index.tsx` |
| 신규 | `src/components/feed/FeedLayoutSwitcher/index.tsx` |
| 신규 | `src/components/feed/FeedSidebar/index.tsx` |
| 신규 | `src/app/feed/a/page.tsx` |
| 신규 | `src/app/feed/b/page.tsx` |

기존 파일 수정 **없음**. 모두 신규 파일로 구현.

---

## 구현 순서

1. `useArticleFeed` 훅 — 무한스크롤 로직 추출
2. `useBookmarks` 훅 — 북마크 로직 추출
3. `FeedTabs` 컴포넌트
4. `FeedLayoutSwitcher` 컴포넌트
5. A안 페이지 (`/feed/a`)
6. `FeedSidebar` 컴포넌트
7. B안 페이지 (`/feed/b`)

---

## 검증
1. `npm run build` — TypeScript 빌드 통과
2. `/feed/a` 접속 → 탭 전환, 무한스크롤, 카드/리스트 전환, 프리뷰, 북마크 동작
3. `/feed/b` 접속 → 사이드바 인기글, 소스 필터, 무한스크롤, 프리뷰, 북마크 동작
4. `/feed/b` 모바일 (크롬 DevTools 375px) → 사이드바 숨김, 탭 모드로 전환
5. 기존 `/` 페이지 영향 없음 확인
