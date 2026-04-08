# 고급 패턴 — Boolean Prop / Context / Provider

## Boolean Prop 폭발 방지

Boolean prop이 3개 이상이면 **조합이 기하급수적으로 늘어나** 테스트·유지보수가 어려워진다.
열거형(union type)으로 대체하여 **유효한 조합만** 허용한다.

```typescript
// ❌ Boolean prop 폭발 — 2³ = 8가지 조합, 유효하지 않은 조합 존재
interface ButtonProps {
  isPrimary?: boolean;
  isSecondary?: boolean;
  isDanger?: boolean;
  isLoading?: boolean;
  isDisabled?: boolean;
}
// isPrimary + isSecondary = true? 의미 없는 조합

// ✅ 열거형으로 유효한 상태만 허용
interface ButtonProps {
  variant: 'primary' | 'secondary' | 'danger';
  state?: 'idle' | 'loading' | 'disabled';
}
```

규칙:
- Boolean prop이 3개 이상이면 열거형 전환 검토
- 상호 배타적 상태(`isPrimary` vs `isSecondary`)는 반드시 union type으로
- `isLoading`처럼 독립적인 boolean은 유지 가능

## Generic Context Interface

Context value를 `{state, actions, meta}` 구조로 통일하면 **소비 측에서 예측 가능**하고, 불필요한 리렌더링을 줄일 수 있다.

```typescript
// ❌ Context value가 flat 객체 — 액션 호출 시 state 구독자도 리렌더링
const TodoContext = createContext<{
  todos: Todo[];
  filter: FilterType;
  addTodo: (text: string) => void;
  toggleTodo: (id: number) => void;
  setFilter: (filter: FilterType) => void;
  activeCount: number;
}>(...);

// ✅ state / actions / meta 분리 — 필요한 것만 구독 가능
interface TodoContextValue {
  state: {
    todos: Todo[];
    filter: FilterType;
  };
  actions: {
    addTodo: (text: string) => void;
    toggleTodo: (id: number) => void;
    setFilter: (filter: FilterType) => void;
  };
  meta: {
    activeCount: number;
    completedCount: number;
  };
}

// 사용 측에서 필요한 부분만 구독
const { actions } = useTodoContext(); // state 변경 시 리렌더링 안됨
```

적용 기준:
- Context에 상태와 액션이 혼재된 경우
- Context 소비자가 5개 이상인 경우
- 불필요한 리렌더링이 관찰되는 경우

## State를 Provider로 끌어올리기

여러 컴포넌트가 공유하는 상태가 특정 컴포넌트에 묶여 있으면 **리팩터링 시 영향 범위가 커진다**.
공유 상태는 Provider로 올리고, 컴포넌트는 **표현에만 집중**시킨다.

```typescript
// ❌ 상태가 특정 컴포넌트에 묶여 있음 → 다른 컴포넌트가 접근하려면 props drilling
function TodoApp() {
  const [todos, setTodos] = useState<Todo[]>([]);
  const [filter, setFilter] = useState<FilterType>('all');

  return (
    <>
      <TodoInput onAdd={(text) => setTodos(prev => [...])} />
      <TodoFilter filter={filter} onFilterChange={setFilter} />
      <TodoList todos={filteredTodos} onToggle={...} onDelete={...} />
      <TodoCount todos={todos} />
    </>
  );
}

// ✅ Provider로 상태 분리 → 컴포넌트는 표현만 담당
function TodoApp() {
  return (
    <TodoProvider>
      <TodoInput />
      <TodoFilter />
      <TodoList />
      <TodoCount />
    </TodoProvider>
  );
}

// 각 컴포넌트는 useTodoContext()로 필요한 것만 가져옴
function TodoInput() {
  const { actions } = useTodoContext();
  // ...
}
```

적용 기준:
- 3개 이상의 컴포넌트가 동일 상태를 공유하는 경우
- Props drilling이 2단계 이상인 경우
- 단, 2개 이하 컴포넌트만 사용하는 상태는 props 전달이 더 명확
