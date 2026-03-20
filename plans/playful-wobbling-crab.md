# 유저 아티클 작성 기능

## Context
DevFeed에 "개인 블로그" 카테고리가 추가됨. 현재 아티클은 크론잡으로만 생성되는데, 유저가 직접 마크다운으로 글을 작성할 수 있도록 확장.

---

## Phase 1: DB 마이그레이션 + 타입

### SQL (Supabase에서 실행)
```sql
-- article 테이블 확장
ALTER TABLE article ADD COLUMN author_user_id INTEGER REFERENCES "user"(id) DEFAULT NULL;
ALTER TABLE article ADD COLUMN content TEXT DEFAULT NULL;
ALTER TABLE article ADD COLUMN is_user_article BOOLEAN DEFAULT FALSE;
CREATE INDEX idx_article_author_user_id ON article(author_user_id) WHERE author_user_id IS NOT NULL;

-- 유저 글 전용 source (1회)
INSERT INTO source (id, name, type, category, url, is_active)
VALUES ('user-articles', '유저 글', 'user', '개인 블로그', '', TRUE);
```

### 타입 변경
- `src/features/feed/sources/types.ts` — `SourceType`에 `"user"` 추가
- `src/features/feed/articles/types.ts` — `ArticleItem`에 `is_user_article`, `author_user_id`, `content` 추가

---

## Phase 2: Backend API

| 메서드 | 경로 | 설명 |
|--------|------|------|
| POST | `/api/v1/auth/articles` | 아티클 생성 (인증 필수) |
| DELETE | `/api/v1/auth/articles/[articleId]` | 본인 글 삭제 |
| GET | `/api/v1/articles/[articleId]` | 아티클 상세 조회 (content 포함) |

- `source_id` = `'user-articles'`, `category` = `'개인 블로그'`
- `url` = `/articles/{id}` (insert 후 update)
- `summary` 미입력 시 content 앞 200자 자동 추출 (마크다운 태그 제거)

### 기존 API 수정
- `GET /api/v1/articles` — select에 `is_user_article` 추가, 목록에서 `content` 제외

---

## Phase 3: 에디터 + 클라이언트 API

### 라이브러리 설치
```bash
npm install @uiw/react-md-editor
```

### 클라이언트 API 함수
- `src/features/feed/articles/api.ts` — `createArticleApi`, `deleteArticleApi`, `getArticleApi` 추가

---

## Phase 4: UI 컴포넌트

### 신규 컴포넌트
| 컴포넌트 | 경로 | 설명 |
|----------|------|------|
| MarkdownEditor | `src/components/common/MarkdownEditor/index.tsx` | @uiw/react-md-editor 래핑, 다크모드 지원 |
| MarkdownRenderer | `src/components/common/MarkdownRenderer/index.tsx` | 마크다운 렌더링 (상세 페이지용) |

### 신규 페이지
| 페이지 | 경로 | 설명 |
|--------|------|------|
| 글쓰기 | `src/app/write/page.tsx` | 제목 + 요약(선택) + 마크다운 에디터 + 발행 |
| 아티클 상세 | `src/app/articles/[id]/page.tsx` | 마크다운 렌더링 + 메타 정보 + 북마크/삭제 |

---

## Phase 5: 기존 컴포넌트 수정

- **ArticleCard** — `is_user_article`일 때 `/articles/{id}`로 내부 이동 (external link X)
- **SourceBadge** — `type: "user"` 스타일 추가
- **Header** — 로그인 시 "글쓰기" 버튼 추가

---

## 주요 파일 목록

### 수정 파일
- `src/features/feed/sources/types.ts`
- `src/features/feed/articles/types.ts`
- `src/features/feed/articles/api.ts`
- `src/app/api/v1/articles/route.ts`
- `src/components/feed/ArticleCard/index.tsx`
- `src/components/feed/SourceBadge/index.tsx`
- `src/components/common/Header/index.tsx`

### 신규 파일
- `src/app/api/v1/auth/articles/route.ts`
- `src/app/api/v1/auth/articles/[articleId]/route.ts`
- `src/app/api/v1/articles/[articleId]/route.ts`
- `src/components/common/MarkdownEditor/index.tsx`
- `src/components/common/MarkdownRenderer/index.tsx`
- `src/app/write/page.tsx`
- `src/app/articles/[id]/page.tsx`

---

## 검증 방법
1. DB 마이그레이션 후 Supabase에서 테이블 확인
2. 로컬 dev 서버에서 `/write` 접속 → 글 작성 → `/articles/{id}`에서 확인
3. 홈 피드에서 유저 글이 "개인 블로그" 카테고리에 표시되는지 확인
4. ArticleCard에서 유저 글 클릭 시 내부 이동되는지 확인
5. 본인 글 삭제 동작 확인
6. 비로그인 시 글쓰기 버튼 미노출 확인
