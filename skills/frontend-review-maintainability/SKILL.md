---
name: frontend-review-maintainability
description: React/Next.js 코드의 유지보수성을 리뷰할 때 사용. DRY 위반, 순환복잡도, 함수 길이, 네이밍 명확성, 매직 값, 에러 처리 구조.
effort: medium
allowed-tools: Read, Glob, Grep
---

# 가독성 & 유지보수성 점검

## DRY 위반

```typescript
// ❌ 동일 로직 반복
function UserList() {
  const [loading, setLoading] = useState(false);
  const fetchUsers = async () => {
    setLoading(true);
    try { const data = await getUsersApi(); setUsers(data); }
    catch { toast.error('오류 발생'); }
    finally { setLoading(false); }
  };
}

function AdminList() {
  const [loading, setLoading] = useState(false);
  const fetchAdmins = async () => {
    setLoading(true);
    try { const data = await getAdminsApi(); setAdmins(data); }
    catch { toast.error('오류 발생'); }
    finally { setLoading(false); }
  };
}

// ✅ 공통 로직 추출
function useFetch<T>(fetchFn: () => Promise<T>) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(false);
  // ...
}
```

점검 항목:
- 동일 패턴의 코드가 3회 이상 반복
- 복사-붙여넣기로 만든 유사 컴포넌트
- API 호출 + 로딩 + 에러 처리 패턴 반복
- 동일한 조건 분기가 여러 곳에 산재

## 순환복잡도 (과도한 중첩)

```typescript
// ❌ 중첩 3단계 이상
if (user) {
  if (user.role === 'admin') {
    if (user.permissions.includes('write')) {
      if (feature.isEnabled) {
        // 실제 로직
      }
    }
  }
}

// ✅ 조기 반환 (early return)
if (!user) return null;
if (user.role !== 'admin') return <Unauthorized />;
if (!user.permissions.includes('write')) return <NoPermission />;
if (!feature.isEnabled) return <FeatureDisabled />;
// 실제 로직
```

점검 항목:
- `if`/`else`/`switch` 중첩 3단계 이상
- 하나의 함수에 `if` 분기 5개 이상
- 삼항 연산자 중첩 (`a ? b ? c : d : e`)
- 복잡한 논리 조건 (`&&`, `||` 3개 이상 조합)

## 함수 / 컴포넌트 크기

점검 기준:
- 단일 함수 **50줄 초과** → 분리 검토
- 단일 컴포넌트 **200줄 초과** → 서브 컴포넌트 분리 검토
- 하나의 파일에 **export 5개 초과** → 파일 분리 검토
- 하나의 컴포넌트에 `useState` **5개 초과** → 커스텀 훅 추출 검토

## 네이밍 불명확

```typescript
// ❌ 모호한 이름
const data = await fetchData();
const temp = items.filter(i => i.active);
const info = getUserInfo();
const flag = checkPermission();
const val = calculateTotal();

// ✅ 의도가 드러나는 이름
const activeUsers = await fetchActiveUsers();
const activeItems = items.filter(item => item.isActive);
const userProfile = getUserProfile();
const hasWritePermission = checkWritePermission();
const orderTotal = calculateOrderTotal();
```

점검 항목:
- `data`, `info`, `temp`, `result`, `val`, `flag` 등 범용 이름
- 약어 남용 (`usr`, `btn`, `msg`, `idx`)
- boolean에 `is`/`has`/`should`/`can` 접두사 누락
- 이벤트 핸들러에 `handle` 접두사 누락

## 매직 넘버 / 스트링

```typescript
// ❌ 의미 불명의 하드코딩
if (items.length > 50) { ... }
setTimeout(retry, 3000);
if (status === 'A01') { ... }

// ✅ 상수로 의미 부여
const MAX_DISPLAY_ITEMS = 50;
const RETRY_DELAY_MS = 3000;
const STATUS_ACTIVE = 'A01';

if (items.length > MAX_DISPLAY_ITEMS) { ... }
setTimeout(retry, RETRY_DELAY_MS);
if (status === STATUS_ACTIVE) { ... }
```

점검 항목:
- 숫자가 직접 코드에 삽입 (`0`, `1` 제외)
- 문자열이 조건문에 직접 비교
- 같은 매직값이 여러 곳에서 사용
- 타임아웃/지연 시간이 하드코딩

## 에러 핸들링 구조

```typescript
// ❌ 빈 catch 블록 (에러 무시)
try { await saveData(); }
catch {}

// ❌ 에러 삼키기 (로그만 찍고 무시)
catch (error) { console.log(error); }

// ❌ 사용자 피드백 없음
catch (error) { return null; }

// ✅ 적절한 에러 처리
catch (error) {
  if (axios.isAxiosError(error) && error.response?.status === 409) {
    toast.error('이미 존재하는 항목입니다');
    return { data: null, error: 'duplicate' };
  }
  toast.error('저장에 실패했습니다');
  return { data: null, error: 'unknown' };
}
```

점검 항목:
- 빈 `catch {}` 블록
- `catch` 안에서 `console.log`만 하고 종료
- 에러 발생 시 사용자에게 아무 피드백 없음
- 모든 에러를 동일한 메시지로 처리 (구분 없음)
- `catch (error: any)` 사용 (타입 미지정)
