# localStorage 패턴

## SSR 안전한 localStorage 접근

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

## localStorage 저장 실패 롤백

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
