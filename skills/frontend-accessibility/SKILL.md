---
name: frontend-accessibility
description: Use when creating interactive UI components. Enforces ARIA roles, keyboard navigation, label usage, html lang attribute, and focus management patterns.
allowed-tools: Read, Write, Edit, Glob, Grep
---

# 접근성 (Accessibility) 패턴

## html lang 속성

페이지 언어와 `<html>` 태그의 `lang` 속성을 일치시킨다. 스크린 리더가 올바른 언어로 콘텐츠를 읽는 데 필수.

```typescript
// ❌ 한국어 서비스인데 lang="en"
<html lang="en">

// ✅ 실제 콘텐츠 언어와 일치
<html lang="ko">
```

Next.js App Router에서는 `src/app/layout.tsx`에서 설정:
```typescript
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ko">
      <body>{children}</body>
    </html>
  );
}
```

## Label 사용 규칙

### label과 aria-label 중복 금지

하나의 입력 요소에 `<label htmlFor>` 와 `aria-label`을 동시에 사용하면 스크린 리더가 둘 다 읽는다.

```typescript
// ❌ 중복 — 스크린 리더가 "할 일 입력 할 일 입력" 읽음
<label htmlFor="todo-input">할 일 입력</label>
<input id="todo-input" aria-label="할 일 입력" />

// ✅ 시각적 label이 있으면 htmlFor만 사용
<label htmlFor="todo-input">할 일 입력</label>
<input id="todo-input" />

// ✅ 시각적 label이 없으면 aria-label만 사용
<input aria-label="할 일 입력" />
```

선택 기준:
- 화면에 텍스트 label이 보임 → `<label htmlFor>`
- 화면에 label 없이 아이콘만 있음 → `aria-label`
- 둘 다 사용 → 금지

## ARIA Tablist 패턴

탭/필터 UI에는 WAI-ARIA tablist 역할을 부여한다.

```typescript
// ❌ role 없는 버튼 나열 — 스크린 리더가 탭 구조를 인식 못함
<div>
  <button onClick={() => setFilter('all')}>전체</button>
  <button onClick={() => setFilter('active')}>활성</button>
  <button onClick={() => setFilter('completed')}>완료</button>
</div>

// ✅ WAI-ARIA tablist 패턴
<div role="tablist" aria-label="할 일 필터">
  <button
    role="tab"
    aria-selected={filter === 'all'}
    tabIndex={filter === 'all' ? 0 : -1}
    onClick={() => setFilter('all')}
  >
    전체
  </button>
  <button
    role="tab"
    aria-selected={filter === 'active'}
    tabIndex={filter === 'active' ? 0 : -1}
    onClick={() => setFilter('active')}
  >
    활성
  </button>
</div>
```

필수 속성:
- 컨테이너: `role="tablist"` + `aria-label`
- 각 탭: `role="tab"` + `aria-selected`
- 선택된 탭만 `tabIndex={0}`, 나머지는 `tabIndex={-1}`

## 키보드 내비게이션

### Tablist 화살표 키 이동

탭 목록에서 `ArrowLeft`/`ArrowRight`로 포커스를 이동해야 한다.

```typescript
const handleKeyDown = (e: React.KeyboardEvent, currentIndex: number) => {
  const tabs = buttonRefs.current;
  let nextIndex: number | null = null;

  if (e.key === 'ArrowRight') {
    nextIndex = (currentIndex + 1) % tabs.length;
  } else if (e.key === 'ArrowLeft') {
    nextIndex = (currentIndex - 1 + tabs.length) % tabs.length;
  }

  if (nextIndex !== null) {
    e.preventDefault();
    tabs[nextIndex]?.focus();
  }
};
```

규칙:
- `ArrowRight`: 다음 탭으로 이동 (마지막 → 처음 순환)
- `ArrowLeft`: 이전 탭으로 이동 (처음 → 마지막 순환)
- `e.preventDefault()`: 브라우저 기본 스크롤 방지
- 포커스 이동 시 해당 탭에 `focus()` 호출

### 기본 키보드 접근성

모든 인터랙티브 요소는 키보드로 접근 가능해야 한다.

```typescript
// ❌ div에 onClick만 → 키보드 사용자 접근 불가
<div onClick={handleClick}>클릭</div>

// ✅ button 사용 (기본 키보드 지원)
<button onClick={handleClick}>클릭</button>

// ✅ div를 꼭 써야 하면 role + tabIndex + onKeyDown 추가
<div
  role="button"
  tabIndex={0}
  onClick={handleClick}
  onKeyDown={(e) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      handleClick();
    }
  }}
>
  클릭
</div>
```

## 체크리스트

컴포넌트 작성 시 확인:
- [ ] `<html lang>` 속성이 콘텐츠 언어와 일치하는가
- [ ] 모든 `<input>`에 `<label>` 또는 `aria-label`이 있는가 (중복 아닌 하나만)
- [ ] 탭/필터 UI에 `role="tablist"` + `role="tab"` + `aria-selected`가 있는가
- [ ] 탭 UI에서 화살표 키로 이동이 가능한가
- [ ] 인터랙티브 요소가 `<button>` 또는 적절한 role을 가지는가
- [ ] 포커스 순서가 시각적 순서와 일치하는가
