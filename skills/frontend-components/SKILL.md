---
name: frontend-components
description: React 컴포넌트 생성/수정 시 사용. directory/index.tsx 패턴, import 순서, Props 타입 정의, 조건부 렌더링 패턴.
effort: low
allowed-tools: Read, Write, Edit, Glob, Grep
---

# 컴포넌트 작성 규칙

## 필수: 디렉토리/index.tsx 패턴

모든 컴포넌트는 반드시 디렉토리를 만들고 그 안에 index.tsx 생성:
```
✅ components/admin/accounts/AdminTable/index.tsx
✅ components/admin/accounts/AddAdminModal/index.tsx

❌ components/AdminTable.tsx (단일 파일 금지)
```

## 기본 구조
```typescript
// components/admin/accounts/AdminTable/index.tsx
"use client"; // 필요시 최상단

import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { api } from '@/lib/api/axios';
import type { AdminData } from '@/features/admin/accounts/types';

// Props 타입 정의
interface AdminTableProps {
  data: AdminData[];
  onEdit?: (id: string) => void;
}

// 컴포넌트 정의
export function AdminTable({ data, onEdit }: AdminTableProps) {
  const [selectedId, setSelectedId] = useState<string | null>(null);

  return (
    <div className="flex flex-col gap-2">
      {/* 구현 */}
    </div>
  );
}
```

## "use client" 사용 기준

Next.js App Router에서 컴포넌트는 기본적으로 서버 컴포넌트.
아래 경우에만 `"use client"` 를 최상단에 추가:
- useState, useEffect 등 React 훅 사용
- onClick, onChange 등 이벤트 핸들러 사용
- 브라우저 API 접근 (localStorage, window 등)
- Context의 useContext 사용

서버 컴포넌트에서 가능한 것:
- 데이터 fetch (async 컴포넌트)
- 메타데이터 설정
- 정적 렌더링

## 상태 업데이트 패턴

### 함수형 업데이터 (필수)

상태를 업데이트할 때 **이전 상태에 의존하면 반드시 함수형 업데이터**를 사용한다.
`useCallback`, `useEffect` 안에서 직접 상태 값을 참조하면 클로저에 캡처된 옛날 값을 사용하게 된다.

```typescript
// ❌ stale closure 위험 — count가 클로저에 캡처됨
const handleClick = useCallback(() => {
  setCount(count + 1);
}, []);

// ✅ 함수형 업데이터 — 항상 최신 상태 기반
const handleClick = useCallback(() => {
  setCount(prev => prev + 1);
}, []);

// ✅ 배열/객체도 동일
const addItem = useCallback((item: Item) => {
  setItems(prev => [...prev, item]);
}, []);
```

적용 기준:
- `setState(prev => ...)` 형태를 기본으로 사용
- 이전 상태와 무관한 값 설정(`setLoading(true)`)은 직접 전달 가능

## Browser API 사용 패턴

localStorage를 사용하는 컴포넌트를 만들 때는 `references/localstorage-patterns.md`를 참고한다.
핵심만 요약하면:
- **초기 로드**: 반드시 `useEffect` 안에서 접근 (SSR 에러 방지)
- **저장**: 함수형 업데이터 + `try/catch` → 실패 시 롤백
- **버전 관리**: 키에 버전 프리픽스 (`todos:v2`)

## RSC 직렬화 최소화

서버 컴포넌트에서 클라이언트 컴포넌트로 props를 전달할 때, **필요한 필드만** 추려서 전달한다.
전체 객체를 직렬화하면 번들 크기가 커지고, 직렬화 불가능한 값(함수, Date, Map 등)이 포함되면 런타임 에러가 발생한다.

```typescript
// ❌ 전체 DB 객체를 그대로 전달 — 불필요한 필드 + 직렬화 문제
async function PostPage({ params }: Props) {
  const post = await db.post.findUnique({ where: { id: params.id } });
  return <PostEditor post={post} />; // createdAt(Date), author(관계) 등 포함
}

// ✅ 필요한 필드만 추출하여 전달
async function PostPage({ params }: Props) {
  const post = await db.post.findUnique({ where: { id: params.id } });
  return (
    <PostEditor
      id={post.id}
      title={post.title}
      content={post.content}
    />
  );
}
```

점검 항목:
- 서버 → 클라이언트 전달 시 `Date`, `Map`, `Set`, 함수 포함 여부
- DB 모델 객체를 그대로 props로 전달하는 경우
- 클라이언트에서 사용하지 않는 필드까지 전달하는 경우

## 지연 상태 초기화

`useState` 초기값이 **비용이 큰 계산**이면 함수 형태로 전달한다(lazy initializer).
함수 형태가 아니면 매 렌더마다 계산이 실행되고 결과만 버려진다.

```typescript
// ❌ 매 렌더마다 buildIndex 실행 (결과는 첫 렌더만 사용)
const [index, setIndex] = useState(buildIndex(items));

// ✅ 함수 형태 → 첫 렌더에서만 실행
const [index, setIndex] = useState(() => buildIndex(items));

// ❌ JSON 파싱도 동일
const [config, setConfig] = useState(JSON.parse(savedConfig));

// ✅ lazy initializer
const [config, setConfig] = useState(() => JSON.parse(savedConfig));
```

적용 기준:
- `JSON.parse`, 배열 정렬/필터, 인덱스 생성 등 O(n) 이상 연산
- 단순 원시값(`useState(0)`, `useState('')`)은 불필요

## Compound Components 패턴

관련된 컴포넌트를 네임스페이스로 묶어 **소속 관계를 명확히** 한다.
독립적으로 쓰이지 않는 서브 컴포넌트가 최상위에 노출되는 것을 방지한다.

```typescript
// ❌ 서브 컴포넌트가 독립 export → 소속 관계 불명확
import { ComposerFrame } from './ComposerFrame';
import { ComposerInput } from './ComposerInput';
import { ComposerButton } from './ComposerButton';

<ComposerFrame>
  <ComposerInput />
  <ComposerButton />
</ComposerFrame>

// ✅ 네임스페이스 패턴 → 소속 관계 명확
import { Composer } from './Composer';

<Composer.Frame>
  <Composer.Input />
  <Composer.Button />
</Composer.Frame>

// 구현
export const Composer = {
  Frame: ComposerFrame,
  Input: ComposerInput,
  Button: ComposerButton,
};
```

적용 기준:
- 서브 컴포넌트가 부모 없이는 의미가 없는 경우 (Form.Field, Table.Row 등)
- 3개 이상의 관련 컴포넌트가 항상 함께 사용되는 경우

## useTransition 패턴

비긴급 상태 업데이트는 `useTransition`으로 감싸서 UI 응답성을 유지한다.
긴급 업데이트(입력)와 비긴급 업데이트(결과 필터링)를 분리한다.

```typescript
// ❌ 입력할 때마다 무거운 필터링이 동기 실행 → 타이핑 지연
function SearchPage({ items }: Props) {
  const [query, setQuery] = useState('');
  const filtered = items.filter(item =>
    item.name.toLowerCase().includes(query.toLowerCase())
  );

  return (
    <input
      value={query}
      onChange={(e) => setQuery(e.target.value)} // 타이핑마다 블로킹
    />
  );
}

// ✅ useTransition으로 비긴급 업데이트 분리
function SearchPage({ items }: Props) {
  const [query, setQuery] = useState('');
  const [deferredQuery, setDeferredQuery] = useState('');
  const [isPending, startTransition] = useTransition();

  const filtered = items.filter(item =>
    item.name.toLowerCase().includes(deferredQuery.toLowerCase())
  );

  return (
    <>
      <input
        value={query}
        onChange={(e) => {
          setQuery(e.target.value); // 긴급: 즉시 반영
          startTransition(() => {
            setDeferredQuery(e.target.value); // 비긴급: 지연 가능
          });
        }}
      />
      {isPending && <Spinner />}
    </>
  );
}
```

적용 기준:
- 대량 리스트 필터링/정렬과 입력이 동시에 발생하는 경우
- 탭 전환 시 무거운 컴포넌트 렌더링이 필요한 경우
- `useDeferredValue`도 동일 목적으로 사용 가능

## Export 규칙
```typescript
// ✅ named export 사용
export function AdminTable() { ... }

// ❌ default export 금지
export default function AdminTable() { ... }
```

## 복잡한 컴포넌트 구조 (서브 컴포넌트 포함)
```
AdminTable/
├── index.tsx              # 메인 컴포넌트
├── TableHeader/
│   └── index.tsx          # 서브 컴포넌트
├── TableRow/
│   └── index.tsx
├── hooks.ts               # 컴포넌트 전용 훅
└── types.ts               # 컴포넌트 전용 타입
```

타입 위치 규칙:
- **Props 타입**: 각 컴포넌트의 index.tsx 파일 안에 정의 (해당 컴포넌트에서만 사용)
- **공유 타입**: `types.ts`에 정의 (서브컴포넌트 간 공유하는 타입, 예: TableRow와 TableHeader가 같은 ColumnDef 타입을 쓸 때)
- **도메인 타입**: `features/[domain]/types.ts`에 정의 (API 요청/응답 타입 등 컴포넌트 밖에서도 쓰이는 타입)

## Import 순서 (필수)
```typescript
// 1. React & Next.js
import { useState } from 'react';
import Link from 'next/link';

// 2. 외부 라이브러리
import { motion } from 'framer-motion';

// 3. UI 컴포넌트
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';

// 4. 내부 컴포넌트
import { AdminTable } from '@/components/admin/accounts/AdminTable';

// 5. Hooks & Utils
import { useMobile } from '@/hooks/use-mobile';
import { cn } from '@/lib/utils';

// 6. 타입 & 상수
import type { UserData } from './types';
import { BASE_URL } from './constants';
```

## 조건부 렌더링
```typescript
// ✅ Good
{description && <p>{description}</p>}

// ❌ Bad
{description ? <p>{description}</p> : null}
```

## 이벤트 핸들러
```typescript
// Props 콜백: on 접두사
interface Props {
  onSubmit: () => void;    // ✅ props는 on 접두사
  onEdit?: (id: string) => void;
}

// 내부 핸들러: handle 접두사
const handleSubmit = () => {
  // 로직 처리
  onSubmit();
}
const handleClick = () => { ... }

// ❌ Bad
const onSubmit = () => { ... }  // 내부에서 on 접두사 사용
const submit = () => { ... }    // 접두사 없음
```

## Next.js 컴포넌트 사용 (HTML 태그 대체)

HTML 태그 대신 Next.js 제공 컴포넌트를 사용한다. 최적화(프리페칭, 이미지 최적화 등)가 자동 적용된다.

```typescript
// ✅ Good: Next.js 컴포넌트
import Link from 'next/link';
import Image from 'next/image';

<Link href="/about">소개</Link>
<Image src="/logo.png" alt="로고" width={100} height={50} />

// ❌ Bad: HTML 태그 직접 사용
<a href="/about">소개</a>
<img src="/logo.png" alt="로고" />
```

| HTML 태그 | Next.js 컴포넌트 | 이유 |
|-----------|-----------------|------|
| `<a>` | `<Link>` | 클라이언트 사이드 네비게이션, 프리페칭 |
| `<img>` | `<Image>` | 자동 최적화, lazy loading, 레이아웃 시프트 방지 |

### `<a>` 태그 허용 케이스
- 외부 URL (`https://...`): 클라이언트 사이드 라우팅 필요 없음
- `mailto:`, `tel:` 링크: 페이지 이동이 아님
- 파일 다운로드 (`download` 속성): `<Link>`에서 미지원

### `<img>` 태그 허용 케이스
- 이메일 템플릿 / 정적 HTML: Next.js 런타임 밖
- CMS 등 외부에서 주입된 HTML: `dangerouslySetInnerHTML` 내부

## shadcn/ui 컴포넌트 사용 (HTML 폼/UI 요소 대체)

HTML 기본 폼·UI 요소 대신 **shadcn/ui 컴포넌트를 우선 사용**한다. 일관된 디자인과 접근성이 자동 적용된다.
UI 라이브러리 우선순위: Shadcn UI > Kibo UI > Radix UI > Lucide Icons.
HTML → shadcn/ui 매핑 테이블은 `references/shadcn-mapping.md`를 참고.

## Boolean Props
```typescript
// ✅ Good
<Button disabled />
<Input required />

// ❌ Bad
<Button disabled={true} />
<Input required={true} />
```

## 메모이제이션 사용 기준

꼭 필요한 경우에만 사용한다. 무분별한 memo/useCallback/useMemo는 복잡도만 높인다.
상세 규칙과 사용/금지 케이스는 `references/memoization.md`를 참고.
