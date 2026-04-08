---
name: frontend-review-bugs
description: React/Next.js 코드의 로직 에러, 런타임 버그, 비동기 이슈를 리뷰할 때 사용. null 처리, 조건 오류, 무한 루프, 상태 관리 버그, 타입 불일치.
effort: medium
allowed-tools: Read, Glob, Grep
---

# 버그 & 로직 결함 탐지

## Null / Undefined 참조

```typescript
// ❌ 옵셔널 체이닝 누락
const name = user.profile.name; // user.profile이 undefined일 수 있음

// ✅ 안전한 접근
const name = user?.profile?.name ?? '기본값';
```

점검 항목:
- 옵셔널 체이닝(`?.`) 누락된 중첩 접근
- 빈 배열/객체에 대한 인덱스 접근 (`arr[0]` without length check)
- API 응답 데이터의 nullish 처리 누락
- `undefined`를 props로 전달하는 경우

## 조건문 오류

```typescript
// ❌ Off-by-one
for (let i = 0; i <= items.length; i++) // 마지막 인덱스 초과

// ❌ 잘못된 비교
if (status = 'active') // 할당 vs 비교

// ❌ 누락된 분기
if (type === 'admin') { ... }
else if (type === 'user') { ... }
// 'guest' 케이스 누락
```

점검 항목:
- `<=` vs `<` 경계값 오류
- `=` vs `===` 할당/비교 혼동
- switch/if-else 누락된 분기
- falsy 값 혼동 (`0`, `""`, `null`, `undefined`, `false`)

## 비동기 처리 실수

```typescript
// ❌ await 누락
const data = fetchData(); // Promise 객체가 그대로 할당

// ❌ 경쟁 조건
useEffect(() => {
  const fetchData = async () => {
    const result = await getUser();
    setUser(result); // 컴포넌트 언마운트 후 setState
  };
  fetchData();
}, []);

// ✅ cleanup으로 경쟁 조건 방지
useEffect(() => {
  let cancelled = false;
  const fetchData = async () => {
    const result = await getUser();
    if (!cancelled) setUser(result);
  };
  fetchData();
  return () => { cancelled = true; };
}, []);
```

점검 항목:
- `async` 함수에서 `await` 누락
- Promise 에러 미처리 (`.catch()` 또는 try-catch 없음)
- 언마운트 후 상태 업데이트 → 메모리 누수는 frontend-review-performance에서 다룸. 여기선 cleanup 누락으로 인한 **런타임 에러**(setState on unmounted)만 점검
- 병렬 가능한 요청의 순차 실행 (`Promise.all` 미활용)

## 무한 루프 / 무한 리렌더링

```typescript
// ❌ 매 렌더마다 새 객체 → 무한 루프
useEffect(() => {
  fetchData(filter);
}, [{ page, keyword }]); // 객체는 매번 새 참조

// ✅ 원시값으로 분리
useEffect(() => {
  fetchData({ page, keyword });
}, [page, keyword]);
```

점검 항목:
- `useEffect` 의존성 배열에 객체/배열/함수 직접 전달
- `useEffect` 안에서 의존성 배열의 상태를 변경
- 의존성 배열 누락 (빈 배열이어야 하는데 생략)
- `setState`를 렌더 본문에서 직접 호출

## 상태 관리 버그

```typescript
// ❌ Stale closure
const handleClick = useCallback(() => {
  setCount(count + 1); // count가 캡처된 시점의 값
}, []); // 의존성에 count 누락

// ✅ 함수형 업데이트
const handleClick = useCallback(() => {
  setCount(prev => prev + 1);
}, []);

// ❌ 직접 mutation
const newItems = items;
newItems.push(newItem); // 원본 배열 변경
setItems(newItems); // 같은 참조라 리렌더링 안됨

// ✅ 불변 업데이트
setItems(prev => [...prev, newItem]);
```

점검 항목:
- `useCallback`/`useMemo` 의존성 배열 누락으로 인한 stale closure
- 배열/객체 직접 mutation 후 setState
- 같은 참조로 setState (리렌더링 안됨)
- 파생 가능한 상태를 별도 state로 관리

## 이중 저장 (Side Effect 중복)

```typescript
// ❌ useEffect에서도 저장하고, mutation 함수에서도 저장 → 2번 실행
const [todos, setTodos] = useState<Todo[]>([]);

useEffect(() => {
  localStorage.setItem('todos', JSON.stringify(todos)); // 저장 1
}, [todos]);

const addTodo = (text: string) => {
  setTodos(prev => {
    const next = [...prev, { id: Date.now(), text }];
    localStorage.setItem('todos', JSON.stringify(next)); // 저장 2 (중복!)
    return next;
  });
};

// ✅ 저장 경로 단일화 — mutation 함수에서만 저장
useEffect(() => {
  const saved = loadFromStorage();
  setTodos(saved); // 초기 로드만 담당
}, []);

const addTodo = (text: string) => {
  setTodos(prev => {
    const next = [...prev, { id: Date.now(), text }];
    saveToStorage(next); // 여기서만 저장
    return next;
  });
};
```

점검 항목:
- `useEffect([state])` 감지 저장 + mutation 함수 내 저장이 동시에 존재
- 기존 저장 로직에 새 저장 방식 추가 시 기존 코드 제거 여부
- 한 데이터의 저장 경로가 2개 이상인 경우

## useEffect 내 동기 setState (파생 상태 안티패턴)

`eslint-plugin-react-hooks` v6.1+의 `react-hooks/set-state-in-effect` 규칙이 자동 탐지하는 패턴.
useEffect 안에서 동기적으로 setState를 호출하면 **불필요한 리렌더링이 2번** 발생한다.

```typescript
// ❌ 파생 상태를 useState + useEffect로 관리 → 렌더 2회
const [firstName, setFirstName] = useState('Taylor');
const [lastName, setLastName] = useState('Swift');
const [fullName, setFullName] = useState('');

useEffect(() => {
  setFullName(firstName + ' ' + lastName); // 경고: cascading render
}, [firstName, lastName]);

// ✅ 렌더링 중 직접 계산 → 렌더 1회
const fullName = firstName + ' ' + lastName;
// 비싼 계산이면 useMemo 사용
// const fullName = useMemo(() => expensive(firstName, lastName), [firstName, lastName]);
```

| 상황 | 올바른 해결 |
|------|-----------|
| 다른 state/props로 계산 가능한 값 | 렌더 중 직접 계산 또는 `useMemo` |
| props 변경 시 state 리셋 | `key` prop으로 컴포넌트 리마운트 |
| 초기값을 Effect에서 설정 | `useState` 초기값으로 이동 |
| 동기적 로딩 상태 설정 | `useState(true)`로 초기값 변경 |

허용되는 패턴 (경고 미발생):
- 비동기 콜백 안의 setState (`fetch().then(() => setState(...))`)
- ref에서 읽은 값으로 setState (`inputRef.current.offsetWidth`)
- WebSocket/EventSource 구독 콜백 안의 setState

> 일부 정당한 패턴에서 false positive 발생 가능. 확실히 정당한 경우 `// eslint-disable-next-line react-hooks/set-state-in-effect`로 개별 비활성화.

## 조건부 렌더링 0 버그

```typescript
// ❌ count가 0이면 "0"이 렌더링됨 (falsy지만 JSX에서 숫자 0은 출력됨)
{count && <span className="badge">{count}</span>}
// count = 0 → 화면에 "0" 출력

// ✅ 명시적 비교
{count > 0 ? <span className="badge">{count}</span> : null}

// ✅ 또는 Boolean 변환
{!!count && <span className="badge">{count}</span>}
```

점검 항목:
- `{number && <JSX />}` 패턴에서 0이 렌더링되는 케이스
- `{array.length && <JSX />}` — 빈 배열이면 `0` 출력
- `&&` 좌항이 `number` 타입인 모든 조건부 렌더링

## StrictMode 이중 실행 방지 (init-once)

```typescript
// ❌ 개발 모드 StrictMode에서 2번 실행됨
useEffect(() => {
  loadFromStorage();
  checkAuthToken();
  initAnalytics();
}, []);

// ✅ 모듈 레벨 가드로 1번만 실행
let didInit = false;

function App() {
  useEffect(() => {
    if (didInit) return;
    didInit = true;
    loadFromStorage();
    checkAuthToken();
    initAnalytics();
  }, []);
}
```

점검 항목:
- 앱 초기화 로직(인증, 분석 도구, 스토리지 로드)이 `useEffect([], [])`에만 의존
- 개발 모드에서 2번 실행되면 문제가 되는 side effect (API 호출, 이벤트 등록 등)

## 타입 불일치

```typescript
// ❌ 런타임에 터지는 as 캐스팅
const user = response.data as UserData; // 실제로 다른 타입일 수 있음

// ❌ 제네릭 타입 불일치
const [data, setData] = useState<string[]>(null); // null은 string[]이 아님

// ✅ 타입 안전
const [data, setData] = useState<string[] | null>(null);
```

점검 항목:
- `as` 캐스팅으로 타입 강제 변환 (런타임 불일치 위험)
- 제네릭 타입과 실제 초기값 불일치
- API 응답 타입과 실제 데이터 구조 불일치
- `event.target.value` 등 DOM 이벤트 타입 처리
