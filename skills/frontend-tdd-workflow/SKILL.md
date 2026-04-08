---
name: frontend-tdd-workflow
description: TDD로 기능을 구현할 때 사용. Red-Green-Refactor 사이클, 인터페이스 우선 설계, 한 번에 하나의 테스트, 커버리지 80% 목표.
effort: high
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# TDD 워크플로우 규칙

## 핵심 사이클: Red → Green → Refactor

```
[RED]       실패하는 테스트를 먼저 작성한다
               ↓
[GREEN]     테스트를 통과하는 최소한의 코드를 작성한다
               ↓
[REFACTOR]  코드를 정리한다 (테스트는 계속 통과해야 함)
               ↓
            다음 테스트 케이스로 반복
```

## TDD 실행 순서

### 1단계: 인터페이스/타입 먼저 정의

구현 전에 입출력의 형태를 확정한다.

```typescript
// ✅ 타입 먼저 정의
interface FormatPriceOptions {
  currency?: string
  locale?: string
}

function formatPrice(price: number, options?: FormatPriceOptions): string {
  throw new Error('Not implemented')  // 아직 구현하지 않음
}
```

### 2단계: 테스트 케이스 목록 작성

구현 전에 어떤 케이스를 테스트할지 목록을 만든다.

```typescript
describe('formatPrice', () => {
  // 정상 케이스
  it.todo('양수를 원화 형식으로 변환한다')
  it.todo('0을 처리한다')
  it.todo('음수를 처리한다')

  // 옵션 케이스
  it.todo('다른 통화를 지정할 수 있다')
  it.todo('다른 로케일을 지정할 수 있다')

  // 엣지 케이스
  it.todo('소수점이 있는 숫자를 처리한다')
  it.todo('매우 큰 숫자를 처리한다')
})
```

### 3단계: 한 번에 하나의 테스트만 구현

```typescript
// [RED] 첫 번째 테스트 작성 — 실패함
it('양수를 원화 형식으로 변환한다', () => {
  expect(formatPrice(1000)).toBe('1,000원')
})
// → ❌ Error: Not implemented
```

```typescript
// [GREEN] 최소한의 구현으로 통과시킴
function formatPrice(price: number): string {
  return `${price.toLocaleString('ko-KR')}원`
}
// → ✅ 통과
```

```typescript
// [REFACTOR] 정리할 것이 있으면 정리 (테스트 통과 유지)
// → 이 경우는 이미 깔끔하므로 패스
```

```typescript
// 다음 테스트로 이동
it('0을 처리한다', () => {
  expect(formatPrice(0)).toBe('0원')
})
// → ✅ 이미 통과 (구현이 커버함)

it('음수를 처리한다', () => {
  expect(formatPrice(-500)).toBe('-500원')
})
// → ✅ 이미 통과
```

### 4단계: 테스트 실행

```bash
# 단일 실행
npx vitest --run

# 감시 모드 (파일 변경 시 자동 재실행)
npx vitest --watch

# 특정 파일만 실행
npx vitest --run formatPrice.test.ts
```

### 5단계: 커버리지 확인

```bash
npx vitest --run --coverage
```

```
✅ 목표: 80% 이상
⚠️ 50~79%: 추가 테스트 필요
❌ 50% 미만: 핵심 로직 테스트 누락
```

## 금지 사항

```typescript
// ❌ 테스트 없이 구현부터 시작
function formatPrice(price: number): string {
  // 테스트 없이 바로 구현...
}

// ❌ 한 번에 여러 테스트를 한꺼번에 작성
it('양수를 변환한다', ...)
it('음수를 변환한다', ...)
it('옵션을 처리한다', ...)
// → 세 개 다 실패 중인데 셋 다 한 번에 통과시키려 함

// ❌ GREEN 단계에서 과도하게 구현
// (다음 테스트에서 다룰 기능까지 미리 구현하지 않음)

// ❌ REFACTOR에서 동작을 변경
// (리팩토링은 구조만 변경, 동작은 그대로)
```

## 테스트 유형별 TDD 적용

### 유틸 함수

```
1. 인터페이스 정의 (타입)
2. 정상 케이스 테스트 → 구현
3. 엣지 케이스 테스트 → 구현 보강
4. 에러 케이스 테스트 → 에러 처리 추가
```

### 컴포넌트

```
1. Props 인터페이스 정의
2. 렌더링 테스트 → 기본 JSX 작성
3. 이벤트 테스트 → 핸들러 추가
4. 상태 테스트 → useState/로직 추가
5. 조건부 렌더링 테스트 → 분기 추가
```

### API 함수

```
1. 요청/응답 타입 정의
2. 성공 케이스 테스트 (MSW 핸들러) → API 함수 구현
3. 에러 케이스 테스트 → 에러 핸들링 추가
4. 인터셉터 테스트 → 인터셉터 동작 검증
```

## 스킬 연계

| 테스트 대상 | 사용할 스킬 |
|------------|-----------|
| 유틸, 훅 | `frontend-unit-test` |
| 컴포넌트 | `frontend-component-test` |
| API 호출 | `frontend-api-mock-test` |
| 전체 흐름 | `frontend-e2e-test` |
| UI 변경 감지 | `frontend-visual-regression` |

## 점검 항목

- [ ] 구현 전에 타입/인터페이스를 먼저 정의했는가
- [ ] `it.todo()`로 테스트 케이스 목록을 사전에 작성했는가
- [ ] 한 번에 하나의 테스트만 RED → GREEN 사이클을 돌았는가
- [ ] GREEN에서 최소한의 구현만 했는가 (과도한 구현 금지)
- [ ] REFACTOR에서 동작 변경 없이 구조만 정리했는가
- [ ] 모든 테스트가 통과하는 상태에서만 다음 단계로 넘어갔는가
- [ ] 커버리지 80% 이상을 달성했는가
