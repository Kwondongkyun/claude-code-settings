---
name: frontend-review-performance
description: Use when reviewing React/Next.js code for performance issues. Covers unnecessary re-renders, N+1 requests, memory leaks, bundle size, inefficient algorithms, and caching.
allowed-tools: Read, Glob, Grep
---

# 성능 저하 & 리소스 낭비 탐지

## 불필요한 리렌더링

```typescript
// ❌ 매 렌더마다 새 함수/객체 생성
<ChildComponent
  onClick={() => handleClick(id)}     // 매번 새 함수
  style={{ color: 'red' }}            // 매번 새 객체
  config={{ page, keyword }}          // 매번 새 객체
/>

// ✅ 메모이제이션
const handleItemClick = useCallback(() => {
  handleClick(id);
}, [id]);

const config = useMemo(() => ({ page, keyword }), [page, keyword]);

// ❌ 부모 리렌더링 시 불필요하게 따라 리렌더링되는 자식
export function HeavyList({ items }: Props) { ... }

// ✅ React.memo로 props 변경 시에만 리렌더링
export const HeavyList = memo(function HeavyList({ items }: Props) { ... });
```

점검 항목:
- props로 전달되는 인라인 함수/객체/배열
- 무거운 자식 컴포넌트에 `memo` 미적용
- `useMemo`/`useCallback` 의존성 배열 오류
- Context value가 매 렌더마다 새 객체

## N+1 요청

```typescript
// ❌ 루프 안에서 개별 API 호출
const users = await getUsers();
for (const user of users) {
  const profile = await getProfile(user.id); // N번 호출
}

// ✅ 배치 요청
const users = await getUsers();
const profiles = await getProfilesBatch(users.map(u => u.id));

// ❌ 컴포넌트마다 개별 요청
function UserCard({ userId }: Props) {
  useEffect(() => {
    fetchUser(userId); // 카드 10개 → 10번 호출
  }, [userId]);
}

// ✅ 부모에서 한 번에 요청 후 props로 전달
```

점검 항목:
- `for`/`map` 안에서 API 호출
- 리스트 아이템 컴포넌트 각각이 개별 API 호출
- 병렬 가능한 요청을 순차 실행 (`Promise.all` 미활용)
- 동일 데이터를 여러 컴포넌트가 중복 요청

## 메모리 누수

```typescript
// ❌ 이벤트 리스너 정리 안됨
useEffect(() => {
  window.addEventListener('resize', handleResize);
}, []);

// ✅ cleanup 함수로 정리
useEffect(() => {
  window.addEventListener('resize', handleResize);
  return () => window.removeEventListener('resize', handleResize);
}, []);

// ❌ 타이머/인터벌 정리 안됨
useEffect(() => {
  setInterval(pollData, 5000);
}, []);

// ✅ 정리
useEffect(() => {
  const id = setInterval(pollData, 5000);
  return () => clearInterval(id);
}, []);
```

점검 항목:
- `addEventListener` 후 `removeEventListener` 누락
- `setInterval`/`setTimeout` 후 `clearInterval`/`clearTimeout` 누락
- WebSocket/EventSource 연결 해제 누락
- `AbortController`를 사용하지 않는 fetch 요청

## 비효율적 알고리즘

```typescript
// ❌ 중첩 루프 (O(n²))
const duplicates = items.filter((item, i) =>
  items.findIndex(other => other.id === item.id) !== i
);

// ✅ Set 활용 (O(n))
const seen = new Set<string>();
const duplicates = items.filter(item => {
  if (seen.has(item.id)) return true;
  seen.add(item.id);
  return false;
});
```

점검 항목:
- 배열에서 `find`/`findIndex`/`includes`를 반복 호출 (Set/Map으로 대체 가능)
- 대용량 데이터에 `filter` + `map` 체이닝 (단일 루프로 가능)
- 정렬된 데이터에 선형 탐색 (이진 탐색 가능)
- 불필요한 깊은 복사 (`structuredClone` 남용)

## 번들 크기

```typescript
// ❌ 전체 모듈 import
import _ from 'lodash';
import * as Icons from 'lucide-react';

// ✅ 필요한 것만 import (tree-shaking 가능)
import { debounce } from 'lodash-es';
import { Search, Menu } from 'lucide-react';

// ❌ 큰 라이브러리를 즉시 로딩
import { Editor } from '@monaco-editor/react';

// ✅ dynamic import로 지연 로딩
const Editor = dynamic(() => import('@monaco-editor/react'), {
  loading: () => <Skeleton />,
});
```

### 배럴 파일(index.ts) 임포트 회피

```typescript
// ❌ 배럴 파일 경유 → 1,583개 모듈 로딩 (~1MB, 개발 모드 ~2.8초 추가)
import { Check, X, Menu } from 'lucide-react';

// ✅ 직접 경로 임포트 → 3개 모듈만 로딩 (~2KB)
import Check from 'lucide-react/dist/esm/icons/check';
import X from 'lucide-react/dist/esm/icons/x';
import Menu from 'lucide-react/dist/esm/icons/menu';

// ✅ 또는 Next.js 13.5+ 자동 최적화 설정
// next.config.js
module.exports = {
  experimental: {
    optimizePackageImports: ['lucide-react', '@mui/material', 'date-fns']
  }
};
```

영향 받는 라이브러리: `lucide-react`, `@mui/material`, `@tabler/icons-react`, `react-icons`, `date-fns`, `lodash`, `rxjs`

점검 항목:
- `import *` 또는 default import로 전체 모듈 가져오기
- tree-shaking 불가능한 CommonJS 패키지 (`lodash` vs `lodash-es`)
- 배럴 파일(index.ts) 경유 임포트로 불필요한 모듈 로딩
- 초기 로딩에 불필요한 대형 컴포넌트 (dynamic import 미활용)
- 이미지/폰트의 최적화 미적용 (`next/image`, `next/font` 미사용)

## CSS 렌더링 최적화

```css
/* ❌ 긴 리스트에서 모든 아이템을 즉시 렌더링 → 느린 초기 로드 */
.list-item {
  /* 기본 스타일 */
}

/* ✅ content-visibility로 오프스크린 요소 렌더링 지연 → 초기 렌더 최대 10배 빨라짐 */
.list-item {
  content-visibility: auto;
  contain-intrinsic-size: 0 80px; /* 예상 높이 지정 */
}
```

점검 항목:
- 100개 이상의 리스트 아이템에 `content-visibility: auto` 미적용
- 무거운 오프스크린 섹션 (탭 패널 등)에 렌더링 최적화 없음

## 패시브 이벤트 리스너

```typescript
// ❌ 터치/스크롤 이벤트 지연 발생
document.addEventListener('touchstart', handleTouch);
document.addEventListener('wheel', handleWheel);

// ✅ passive: true로 즉시 스크롤 가능 (브라우저가 preventDefault 없음을 알게 됨)
document.addEventListener('touchstart', handleTouch, { passive: true });
document.addEventListener('wheel', handleWheel, { passive: true });
```

점검 항목:
- `touchstart`, `touchmove`, `wheel` 이벤트에 `{ passive: true }` 누락
- 스크롤 관련 이벤트에서 불필요한 `preventDefault()` 호출

## 캐싱 미활용

```typescript
// ❌ 동일 계산을 매 렌더마다 반복
function Dashboard({ items }: Props) {
  const total = items.reduce((sum, item) => sum + item.price, 0); // 매번 재계산
  const sorted = [...items].sort((a, b) => b.price - a.price);   // 매번 재정렬
}

// ✅ useMemo로 캐싱
function Dashboard({ items }: Props) {
  const total = useMemo(
    () => items.reduce((sum, item) => sum + item.price, 0),
    [items]
  );
  const sorted = useMemo(
    () => [...items].sort((a, b) => b.price - a.price),
    [items]
  );
}
```

점검 항목:
- 비용이 큰 계산에 `useMemo` 미적용
- 동일 API를 여러 컴포넌트가 중복 호출 (캐싱 레이어 없음)
- `fetch` 결과를 매번 새로 요청 (SWR/React Query 미활용 시)
- 정적 데이터를 매번 서버에서 가져오기 (ISR/SSG 미활용)
