# 비로그인 유저 아티클 제한 + 로그인 유도

## Context
비로그인 유저에게 소스당 아티클 3개만 보여주고, 나머지는 블러 처리하여 로그인을 유도한다.
홈 페이지(CategoryRow)와 카테고리 상세 페이지 두 곳에 적용.

## 수정 파일

### Step 1: CategoryRow에 비로그인 제한 적용
**수정** `src/components/feed/CategoryRow/index.tsx`
- props에 `isLoggedIn: boolean` 추가
- 비로그인 시 articles를 3개까지만 렌더링
- 3개 이후에 **블러 카드 1개** 추가: ArticleCard와 동일 크기, blur + 오버레이
  - "로그인하면 더 많은 글을 볼 수 있어요" + 로그인 버튼 (Link to `/login`)
- 로그인 유저는 기존과 동일 (제한 없음)

### Step 2: 홈 페이지에서 isLoggedIn 전달
**수정** `src/app/page.tsx`
- `CategoryRow`에 `isLoggedIn={!!user}` prop 추가 (L170)

### Step 3: 카테고리 상세 페이지 제한 적용
**수정** `src/app/category/[slug]/page.tsx`
- 비로그인 시 `displayArticles`를 3개로 slice
- 3개 아래에 블러 오버레이 영역 추가 (row 레이아웃용)
  - 블러된 가짜 행 2~3개 + "로그인하면 더 볼 수 있어요" 오버레이
- `user` 상태는 이미 `useAuth()`로 사용 중

## 블러 UI 설계
- 홈 (카드 레이아웃): 마지막에 블러 카드 1개 추가 (가로 스크롤)
- 카테고리 상세 (행 레이아웃): 3개 행 아래에 블러 행 + 오버레이 (세로 목록)
- 블러 효과: `blur-sm opacity-50` + absolute 오버레이
- CTA: orange 버튼 "로그인" + Link href="/login"

## 적용하지 않는 곳
- 즐겨찾기 섹션: 로그인 필수이므로 변경 불필요
- 마이페이지: 로그인 필수 페이지

## 검증
1. 비로그인 상태에서 홈 → 카테고리당 3개 + 블러 카드 확인
2. 비로그인 상태에서 `/category/[slug]` → 3개 + 블러 오버레이 확인
3. 로그인 후 제한 해제 확인
4. 블러 카드의 로그인 버튼 → `/login` 이동 확인
