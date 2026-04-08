---
name: frontend-fundamentals
description: React/Next.js 컴포넌트 작성/리팩토링 시 사용. Toss Frontend Fundamentals 기반 4원칙(가독성, 예측가능성, 응집도, 결합도) 적용.
effort: medium
allowed-tools: Read, Edit, Glob, Grep
---

# 설계 원칙 (Frontend Fundamentals)

좋은 프론트엔드 코드는 **변경하기 쉬운** 코드입니다.
4가지 기준으로 판단합니다: 가독성, 예측 가능성, 응집도, 결합도.

---

## 1. 가독성 (Readability)

독자가 한 번에 고려해야 할 맥락이 적고, 위에서 아래로 자연스럽게 읽혀야 합니다.

### 동시에 실행되지 않는 코드 분리

```typescript
// ❌ 두 분기가 하나의 컴포넌트에 섞여 있음
function SubmitButton() {
  const isViewer = useRole() === "viewer";

  useEffect(() => {
    if (isViewer) return;
    showButtonAnimation();
  }, [isViewer]);

  return isViewer ? (
    <TextButton disabled>Submit</TextButton>
  ) : (
    <Button type="submit">Submit</Button>
  );
}

// ✅ 분기별로 컴포넌트 분리
function SubmitButton() {
  const isViewer = useRole() === "viewer";
  return isViewer ? <ViewerSubmitButton /> : <AdminSubmitButton />;
}

function ViewerSubmitButton() {
  return <TextButton disabled>Submit</TextButton>;
}

function AdminSubmitButton() {
  useEffect(() => {
    showButtonAnimation();
  }, []);
  return <Button type="submit">Submit</Button>;
}
```

적용 대상:
- 사용자 권한/역할에 따른 다른 UI
- 조건에 따라 완전히 다른 렌더링 로직
- `if`/삼항으로 분기하는 useEffect + JSX 조합

### 복잡한 조건에 이름 붙이기

```typescript
// ❌ 조건의 의도를 파악하기 어려움
const result = products.filter((product) =>
  product.categories.some(
    (category) =>
      category.id === targetCategory.id &&
      product.prices.some((price) => price >= minPrice && price <= maxPrice)
  )
);

// ✅ 조건에 이름을 부여하여 맥락 축소
const matchedProducts = products.filter((product) => {
  return product.categories.some((category) => {
    const isSameCategory = category.id === targetCategory.id;
    const isPriceInRange = product.prices.some(
      (price) => price >= minPrice && price <= maxPrice
    );
    return isSameCategory && isPriceInRange;
  });
});
```

이름을 붙여야 하는 경우:
- 복잡한 논리 조합 (`&&`, `||` 2개 이상)
- 중첩된 콜백 안의 조건
- 재사용되거나 테스트가 필요한 조건

이름이 불필요한 경우:
- 단순한 로직 (`arr.map(x => x * 2)`)
- 한 번만 사용되고 복잡하지 않은 조건

### 위에서 아래로 읽히게 하기

```typescript
// ❌ 삼항 연산자 중첩
const label = isAdmin ? "관리자" : isMember ? "회원" : "게스트";

// ✅ 조기 반환 또는 명확한 분기
function getLabel(role: string) {
  if (role === "admin") return "관리자";
  if (role === "member") return "회원";
  return "게스트";
}
```

규칙:
- 삼항 연산자는 1단계까지만 (중첩 금지)
- 시점 이동 최소화 (함수 정의 → 사용 순서)
- early return으로 핵심 로직을 아래에 배치

---

## 2. 예측 가능성 (Predictability)

이름, 파라미터, 반환값만으로 동작을 예측할 수 있어야 합니다.

### 이름 겹침 방지

```typescript
// ❌ 라이브러리와 같은 이름으로 래퍼 생성
import { http as httpLibrary } from "@some-library/http";

export const http = {
  async get(url: string) {
    const token = await fetchToken();
    return httpLibrary.get(url, {
      headers: { Authorization: `Bearer ${token}` },
    });
  },
};

// ✅ 명확히 구분되는 이름
export const httpService = {
  async getWithAuth(url: string) {
    const token = await fetchToken();
    return httpLibrary.get(url, {
      headers: { Authorization: `Bearer ${token}` },
    });
  },
};
```

규칙:
- 같은 이름이면 같은 동작이어야 함
- 래퍼 함수는 원본과 다른 이름 사용
- 추가 동작이 있으면 이름에 반영 (`get` → `getWithAuth`)

### 반환 타입 통일

```typescript
// ❌ 같은 종류 함수인데 반환 형태가 다름
async function getUser(): Promise<User> { ... }
async function getProducts(): Promise<{ data: Product[] }> { ... }

// ✅ 같은 종류는 같은 형태로 반환
async function getUser(): Promise<User> { ... }
async function getProducts(): Promise<Product[]> { ... }
```

### 숨은 로직 명시화

```typescript
// ❌ 함수 시그니처로 예측 불가능한 부작용
async function fetchBalance(): Promise<number> {
  const balance = await http.get<number>("...");
  logging.log("balance_fetched"); // 숨은 로깅
  return balance;
}

// ✅ 함수는 본래 책임만, 부작용은 호출 지점에서 명시
async function fetchBalance(): Promise<number> {
  const balance = await http.get<number>("...");
  return balance;
}

// 호출 지점
const balance = await fetchBalance();
logging.log("balance_fetched"); // 명시적
```

규칙:
- 함수 시그니처(이름 + 파라미터 + 반환값)로 예측 가능한 로직만 내부에 구현
- 로깅, 분석, 토스트 등 부작용은 호출 지점에서 처리
- 부작용을 포함해야 한다면 이름에 반영

---

## 3. 응집도 (Cohesion)

수정되어야 할 코드가 항상 같이 수정되어야 합니다.

### 함께 수정되는 파일은 같은 디렉토리에

```
// ❌ 파일 종류별 분류 (수정 시 여러 폴더를 돌아다녀야 함)
├─ components/
├─ hooks/
├─ utils/
└─ constants/

// ✅ 도메인별 분류 (관련 파일이 한 곳에)
├─ components/          # UI 컴포넌트
├─ hooks/               # 전역 공통 훅
└─ features/
   └─ user/
      ├─ api.ts
      ├─ types.ts
      ├─ hooks.ts
      └─ constants.ts
```

효과:
- 의존 관계가 디렉토리 구조로 드러남
- 기능 삭제 시 features/user/ 통째로 제거 가능
- 다른 도메인 코드를 import하면 즉시 이상함을 인식

### 매직 넘버 제거 (응집도 관점)

```typescript
// ❌ 같은 값이 여러 파일에 흩어져 있으면 하나만 수정해서 버그 발생
// file1.ts
if (retryCount > 3) { ... }
// file2.ts
for (let i = 0; i < 3; i++) { ... }

// ✅ 상수로 추출하여 한 곳에서 관리
const MAX_RETRY_COUNT = 3;
```

---

## 4. 결합도 (Coupling)

코드 수정 시 영향범위가 작아야 합니다.

### 과도한 공통화 경고

```typescript
// ❌ 여러 페이지에서 쓰는 Hook이지만 페이지마다 동작이 미묘하게 다름
export const useOpenBottomSheet = () => {
  const logger = useLogger();
  return async (info: MaintenanceInfo) => {
    logger.log("바텀시트 열림");
    const result = await bottomSheet.open(info);
    if (result) {
      logger.log("알림받기 클릭");
    }
    closeView(); // 모든 페이지에서 동일하게 닫기?
  };
};
```

규칙:
- 동작이 **완전히 동일**하고 앞으로도 그럴 때만 공통화
- 페이지마다 로깅값, UI, 동작이 달라질 수 있으면 **중복 허용**
- 공통 Hook/컴포넌트 수정 시 모든 의존 코드를 테스트해야 한다면 결합도가 높은 것

### Props Drilling 제거

```typescript
// ❌ 중간 컴포넌트가 사용하지 않는 prop을 전달만 함
function Parent({ items }: Props) {
  return <Middle items={items} />;
}
function Middle({ items }: Props) {
  return <Child items={items} />;  // Middle은 items 안 씀
}

// ✅ 1단계: Composition 패턴
function Parent({ items }: Props) {
  return (
    <Middle>
      <Child items={items} />
    </Middle>
  );
}

// ✅ 2단계: 그래도 깊으면 Context API
const ItemsContext = createContext<Item[]>([]);
```

해결 순서:
1. 먼저 `children` prop으로 Composition 패턴 시도
2. 여전히 깊으면 Context API 적용
3. 모든 prop을 Context로 관리하지는 않기

### 책임 개별 관리

```typescript
// ❌ 하나의 컴포넌트가 데이터 fetch + 가공 + 렌더링 + 에러 처리 전부 담당
function UserPage() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(false);
  // ... fetch + transform + render + error 전부 여기에
}

// ✅ 책임 분리
// 데이터: hooks/useUser.ts
// 가공: utils/transformUser.ts
// 렌더링: components/UserProfile/index.tsx
```

---

### 고급 패턴 (Boolean Prop / Context / Provider)

Context API, Boolean prop 폭발, Provider 패턴 등 특정 상황에서만 쓰는 고급 패턴은 `references/advanced-patterns.md`를 참고한다.

---

## 원칙 간 충돌 시 판단 기준

4가지 기준을 동시에 만족하기 어려울 때:

| 상황 | 우선 기준 |
|------|----------|
| 수정 시 다른 곳에서 버그 날 위험 | **응집도** > 가독성 |
| 수정 영향 범위가 넓음 | **결합도** 줄이기 > DRY |
| 코드를 처음 보는 사람이 이해 못함 | **가독성** > 추상화 |
| 함수 동작을 이름만으로 예측 못함 | **예측 가능성** > 간결함 |
