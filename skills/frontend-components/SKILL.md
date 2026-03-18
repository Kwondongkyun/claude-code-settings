---
name: frontend-components
description: Use when creating or modifying React components. Enforces directory/index.tsx pattern, proper import order, Props type definitions, and conditional rendering patterns.
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

### SSR 안전한 localStorage 접근

Next.js는 서버에서 먼저 렌더링한다. `localStorage`는 브라우저 전용 API라서 **컴포넌트 본문에서 직접 접근하면 서버에서 에러**가 난다. 반드시 `useEffect` 안에서 접근한다.

```typescript
// ❌ 서버 렌더링 시 ReferenceError: localStorage is not defined
function TodoApp() {
  const saved = localStorage.getItem('todos');
  const [todos, setTodos] = useState(JSON.parse(saved || '[]'));
}

// ✅ useEffect로 클라이언트에서만 접근
function TodoApp() {
  const [todos, setTodos] = useState<Todo[]>([]);

  useEffect(() => {
    try {
      const saved = localStorage.getItem('todos');
      if (saved) setTodos(JSON.parse(saved));
    } catch {
      // localStorage 접근 불가 (시크릿 모드 등)
    }
  }, []);
}
```

### localStorage 저장 실패 롤백

localStorage는 **용량 초과(5MB)**, **시크릿 모드**, **스토리지 비활성화** 등으로 실패할 수 있다.
저장 실패 시 **React 상태를 이전 값으로 되돌려서** UI와 실제 저장 데이터의 불일치를 방지한다.

```typescript
// ❌ 저장 실패해도 UI는 변경됨 → 새로고침 시 데이터 증발
const addTodo = (text: string) => {
  const next = [...todos, { id: Date.now(), text, completed: false }];
  setTodos(next);
  localStorage.setItem('todos', JSON.stringify(next)); // 실패하면?
};

// ✅ 함수형 업데이터 + 저장 실패 시 롤백
const addTodo = (text: string) => {
  setTodos(prev => {
    const next = [...prev, { id: Date.now(), text, completed: false }];
    try {
      localStorage.setItem('todos', JSON.stringify(next));
      return next;
    } catch {
      setStorageError('저장 공간이 부족합니다');
      return prev; // 롤백
    }
  });
};
```

패턴 요약:
- **초기 로드**: `useEffect` + `try/catch` → 실패 시 빈 배열
- **저장**: 함수형 업데이터 안에서 `try/catch` → 실패 시 `prev` 반환 (롤백)
- **에러 표시**: `storageError` 상태로 사용자에게 저장 실패 안내

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

## localStorage 버전 관리

저장 구조가 변경되면 이전 버전 데이터가 파싱 에러를 유발한다.
**버전 프리픽스**를 키에 포함하여 구조 변경 시 안전하게 마이그레이션한다.

```typescript
// ❌ 구조 변경 시 기존 사용자 데이터가 깨짐
localStorage.setItem('todos', JSON.stringify(todos));

// ✅ 버전 프리픽스로 안전한 마이그레이션
const STORAGE_KEY = 'todos:v2';

function loadTodos(): Todo[] {
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved) return JSON.parse(saved);

    // v1 → v2 마이그레이션
    const v1 = localStorage.getItem('todos:v1');
    if (v1) {
      const migrated = migrateV1toV2(JSON.parse(v1));
      localStorage.setItem(STORAGE_KEY, JSON.stringify(migrated));
      localStorage.removeItem('todos:v1');
      return migrated;
    }
  } catch { /* 파싱 실패 시 기본값 */ }
  return [];
}
```

적용 기준:
- 저장 데이터의 타입/구조가 변경될 가능성이 있는 경우
- 다수의 사용자가 이미 이전 구조 데이터를 보유한 경우

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

HTML 기본 폼·UI 요소를 사용하기 전에 **반드시 shadcn/ui에 대응 컴포넌트가 있는지 먼저 확인**한다.
대응 컴포넌트가 있으면 HTML 태그 대신 shadcn/ui를 사용한다. 일관된 디자인과 접근성이 자동 적용된다.

### UI 라이브러리 우선순위

1. **Shadcn UI** - 기본 UI 컴포넌트
2. **Kibo UI** - 고급 복합 컴포넌트
3. **Radix UI** - 접근성 기반 원시 컴포넌트
4. **Lucide Icons** - 아이콘 시스템

> shadcn/ui 컴포넌트 목록: https://ui.shadcn.com/docs/components

```typescript
// ✅ Good: shadcn/ui 컴포넌트
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';

<Button onClick={handleClick}>저장</Button>
<Input placeholder="이름 입력" value={name} onChange={handleChange} />

// ❌ Bad: shadcn/ui에 있는데 HTML 태그 직접 사용
<button onClick={handleClick}>저장</button>
<input placeholder="이름 입력" value={name} onChange={handleChange} />
```

### 자주 사용하는 HTML 태그 대체

| HTML 태그 | shadcn/ui 컴포넌트 |
|-----------|-------------------|
| `<button>` | `<Button>` |
| `<input>` | `<Input>` |
| `<textarea>` | `<Textarea>` |
| `<select>` | `<Select>` |
| `<table>` | `<Table>` |
| `<input type="checkbox">` | `<Checkbox>` |
| `<hr>` | `<Separator>` |

### UI 패턴 → shadcn/ui 컴포넌트 매핑

| UI 패턴 | shadcn/ui 컴포넌트 | 비고 |
|---------|-------------------|------|
| 모달/팝업 | `Dialog` | `AlertDialog`는 확인/취소용 |
| 토스트/알림 | `Sonner` 또는 `Toast` | |
| 드롭다운 메뉴 | `DropdownMenu` | 우클릭 메뉴도 포함 |
| 툴팁 | `Tooltip` | |
| 탭 | `Tabs` | |
| 아코디언/접기 | `Accordion` / `Collapsible` | |
| 사이드 패널 | `Sheet` | 슬라이드 아웃 |
| 팝오버 | `Popover` | |
| 날짜 선택 | `Calendar` + `Popover` | |
| 자동완성/콤보박스 | `Command` + `Popover` | |
| 로딩 스켈레톤 | `Skeleton` | |
| 뱃지/태그 | `Badge` | |
| 프로그레스 바 | `Progress` | |

위 표는 대표 예시일 뿐이다. shadcn/ui에서 제공하는 모든 컴포넌트를 우선 사용한다.

### HTML 태그 허용 케이스
- shadcn/ui에 대응 컴포넌트가 없는 경우
- `<form>`, `<fieldset>`, `<legend>` 등 시맨틱 폼 구조 태그

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

기본 원칙: **메모이제이션은 꼭 필요한 경우에만 사용한다.** 무분별한 사용은 코드 복잡도만 높이고 성능 이점이 없다.

### memo - 사용해야 하는 경우
```typescript
// ✅ 무거운 컴포넌트 + 부모가 자주 리렌더링될 때
export const HeavyList = memo(function HeavyList({ items }: Props) {
  return items.map((item) => <ComplexCard key={item.id} data={item} />);
});
```

사용 조건 (모두 충족해야 함):
- 자식 컴포넌트의 렌더링 비용이 큼 (리스트, 차트, 복잡한 UI)
- 부모가 자주 리렌더링됨
- 전달되는 props가 실제로 자주 변경되지 않음

### useCallback - 사용해야 하는 경우
```typescript
// ✅ memo로 감싼 자식에게 전달하는 콜백
const handleClick = useCallback((id: string) => {
  setSelectedId(id);
}, []);

<MemoizedChild onClick={handleClick} />

// ❌ memo로 감싸지 않은 자식에게는 불필요
const handleClick = useCallback(() => { ... }, []); // 의미 없음
<NormalChild onClick={handleClick} />
```

### useMemo - 사용해야 하는 경우
```typescript
// ✅ 비용이 큰 계산 (정렬, 필터, reduce 등)
const sorted = useMemo(
  () => [...items].sort((a, b) => b.price - a.price),
  [items]
);

// ✅ memo로 감싼 자식에게 전달하는 객체/배열
const config = useMemo(() => ({ page, keyword }), [page, keyword]);
<MemoizedChild config={config} />

// ❌ 단순 계산에는 불필요
const total = useMemo(() => a + b, [a, b]); // 오버헤드만 추가
```

### 사용 금지 케이스
```typescript
// ❌ 단순 값 계산
const fullName = useMemo(() => `${first} ${last}`, [first, last]);

// ❌ deps가 매번 바뀌는 useCallback (메모이제이션 효과 없음)
const handleClick = useCallback(() => {
  doSomething(obj);
}, [obj]); // obj가 매 렌더마다 새로 생성되면 무의미

// ❌ 가벼운 컴포넌트에 memo
export const Label = memo(function Label({ text }: Props) {
  return <span>{text}</span>; // 렌더링 비용이 거의 없음
});
```
