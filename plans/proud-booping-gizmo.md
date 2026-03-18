# Todo App 에이전트 팀 구현 계획

## Context
SPEC.md에 정의된 Todo 앱을 에이전트 팀을 구성하여 병렬로 구현한다.
현재 프로젝트는 Next.js 16 + React 19 + TailwindCSS 4 초기 템플릿 상태이며, src/app/ 외에는 아무 파일도 없다.

## 팀 구조

| 역할 | 이름 | 타입 | 담당 |
|------|------|------|------|
| 리더 (나) | - | - | types.ts 생성, page.tsx + layout.tsx 통합, 검증 |
| Agent A | component-dev | `frontend` | UI 컴포넌트 4개 |
| Agent B | hook-dev | `frontend` | useTodos 커스텀 훅 |

## 실행 계획

### Phase 0: 타입 정의 (리더, 동기)
types.ts는 모든 에이전트의 계약(contract) 역할. 리더가 먼저 생성.

**생성 파일**: `src/features/todo/types.ts`
- `Todo` interface, `FilterType` type
- `TodoItemProps`, `TodoListProps`, `TodoInputProps`, `TodoFilterProps`
- `UseTodosReturn` interface

### Phase 1: 병렬 구현 (Agent A + B 동시 실행)

#### Agent A (component-dev) — 컴포넌트 4개
| 파일 | 핵심 구현 |
|------|----------|
| `src/components/todo/todo-item/index.tsx` | 체크박스 + 텍스트 + 삭제 버튼. 완료 시 `line-through text-gray-400` |
| `src/components/todo/todo-list/index.tsx` | TodoItem 목록 렌더링 |
| `src/components/todo/todo-input/index.tsx` | 입력창 + 추가 버튼. Enter 키 지원, 제출 후 초기화 |
| `src/components/todo/todo-filter/index.tsx` | all/active/completed 3개 버튼. 활성 필터 시각 구분 |

- `@/features/todo/types`에서 Props 타입 import
- `"use client"` 선언 불필요 (page.tsx에서 처리)

#### Agent B (hook-dev) — useTodos 훅
**파일**: `src/features/todo/hooks/use-todos.ts`

핵심 로직:
- localStorage 키: `"todos"`, 초기 로드 시 `JSON.parse` 실패 → 빈 배열
- `addTodo`: trim 후 빈 문자열 거부, 200자 초과 거부, 100개 초과 거부, `unshift`로 최신순
- `createdAt`: localStorage 로드 시 `new Date()`로 변환 (JSON 직렬화 시 string이 되므로)
- `filteredTodos`: filter에 따른 파생 데이터
- `setItem` 실패 시 silent fail

### Phase 2: 통합 (리더, Phase 1 완료 후)

#### `src/app/page.tsx` — 전체 재작성
- `"use client"` 선언
- `useTodos` 훅 호출
- 중앙 정렬 카드 레이아웃 (`max-w-lg mx-auto`)
- 배치: TodoInput → TodoFilter → TodoList

#### `src/app/layout.tsx` — 메타데이터 수정
- title: `"Todo App"`, lang: `"ko"`

#### `src/app/globals.css` — 다크모드 제거
- `prefers-color-scheme: dark` 미디어 쿼리 제거 (SPEC 스코프 외)

### Phase 3: 검증 (리더)
1. `npm run build` — 컴파일 에러 확인
2. `npm run dev` — 브라우저 동작 확인
3. 체크리스트: 추가, 빈 문자열 거부, 토글(스타일), 삭제, 필터 3종, 새로고침 후 유지
