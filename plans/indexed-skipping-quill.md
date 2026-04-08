# Context
직접 URL 접근(`/article/[id]`) 또는 모달에서 새로고침 시 풀페이지가 뜨는 것을 막고 홈(`/`)으로 리다이렉트한다.
인터셉트 라우트(`@modal/(.)article/[id]`)는 클라이언트 사이드 내비게이션에서만 작동하므로,
풀페이지 자체를 리다이렉트로 대체하면 된다.

# 변경 파일
- `src/app/article/[id]/page.tsx` — 전체 교체

# 구현
서버 컴포넌트로 전환 후 `redirect('/')` 호출.

```tsx
import { redirect } from "next/navigation";

export default function ArticlePage() {
  redirect("/");
}
```

# 검증
1. `http://localhost:3003/article/3824` 직접 접근 → `/`로 리다이렉트 확인
2. 모달에서 새로고침 → `/`로 리다이렉트 확인
3. 피드에서 카드 클릭 → 여전히 모달로 뜨는지 확인
