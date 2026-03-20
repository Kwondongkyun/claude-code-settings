# Hacker News 완전 제거

## Context
Hacker News 소스를 DB + 코드에서 완전 제거. maily/eopla 때와 동일한 패턴.

## Step 1: DB 정리 (Supabase에서 직접 실행)

```sql
-- 1. 북마크/읽음 기록 중 HN 아티클 참조 제거
DELETE FROM bookmark WHERE article_id IN (SELECT id FROM article WHERE source_id IN (SELECT id FROM source WHERE type = 'hackernews'));
DELETE FROM read_article WHERE article_id IN (SELECT id FROM article WHERE source_id IN (SELECT id FROM source WHERE type = 'hackernews'));

-- 2. HN 아티클 삭제
DELETE FROM article WHERE source_id IN (SELECT id FROM source WHERE type = 'hackernews');

-- 3. HN 소스 삭제
DELETE FROM source WHERE type = 'hackernews';
```

## Step 2: 코드 정리

### `src/app/api/v1/cron/fetch-feeds/route.ts`
- `fetchHackerNews` 함수 전체 삭제
- 분기 `if (s.type === "hackernews") return fetchHackerNews(s);` 제거

### `src/features/feed/sources/types.ts`
- `SourceType`에서 `"hackernews"` 제거 → `"rss" | "devto"`

### `src/components/feed/SourceBadge/index.tsx`
- `TYPE_STYLES`에서 `hackernews` 항목 제거

### `src/app/page.tsx`
- `SOURCE_DOT_COLORS`에서 `hackernews` 항목 제거

### `src/app/layout.tsx`
- 메타데이터 description에서 "HackerNews, " 텍스트 제거

## 검증
1. `npm run build` — 빌드 에러 없음
2. TypeScript 컴파일 에러 없음 (SourceType 변경으로 인한 참조 확인)
