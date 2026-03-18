# UX 개선 구현 계획

## 파일별 변경 내용

### 1. `src/app/page.tsx`
- import: `LogIn`, `Rss` 아이콘 추가
- `sourcesLoaded` state 추가 (listSourcesApi 완료 감지)
- 비로그인 CTA 배너: `!user && sourcesLoaded`일 때 상단에 배너 표시
- 즐겨찾기 빈 상태: `user && favoriteSourceIds.size === 0 && sourcesLoaded`일 때 안내 카드 표시

### 2. `src/app/category/[slug]/page.tsx`
- `hasMore` state 추가 (hasMoreRef와 병행 — ref는 fetchArticles 로직용, state는 렌더링용)
- `fetchArticles` 내부에서 `setHasMore(result.has_more)` 호출
- reset 시 `setHasMore(true)` 초기화
- 무한스크롤 끝 표시: `!loading && !hasMore && articles.length > 0` 조건일 때 "모든 글을 확인했습니다" 메시지 표시
- `CheckCircle` 아이콘 import 추가

### 3. `src/components/feed/CategoryRow/index.tsx`
- `Newspaper` 아이콘 import 추가
- `if (articles.length === 0) return null` 제거
- 대신 articles.length === 0이고 !loading일 때 섹션 헤더 + 빈 상태 메시지 표시
- sourceIds.length === 0인 경우는 여전히 null 반환 (소스 자체가 없는 카테고리)

### 4. `src/app/mypage/page.tsx`
- `Star` 아이콘 외 추가 아이콘 없음 (기존으로 충분)
- 로딩 완료 후 `favoriteIds.size === 0`일 때 즐겨찾기 빈 상태 안내 추가
- 소스 목록 상단에 "즐겨찾기한 소스가 없습니다. 아래에서 별표를 눌러 추가하세요." 안내 카드 표시
