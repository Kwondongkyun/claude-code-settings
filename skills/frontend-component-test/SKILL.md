---
name: frontend-component-test
description: Use when writing component tests for React components. Enforces Vitest + React Testing Library with semantic selectors, render/event/state/async test patterns.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# 컴포넌트 테스트 규칙 (Vitest + React Testing Library)

## 대상

React 컴포넌트의 렌더링, Props, 이벤트, 상태 변화, 조건부 렌더링 검증

## 파일 네이밍

```
✅ components/LoginButton/LoginButton.test.tsx   (같은 디렉토리)
✅ features/auth/components/LoginForm.test.tsx    (같은 디렉토리)

❌ __tests__/LoginButton.test.tsx                 (별도 디렉토리 금지)
```

## 셀렉터 우선순위 (필수)

```typescript
// 1순위: Role (접근성 기반, 가장 안정적)
screen.getByRole('button', { name: '로그인' })
screen.getByRole('heading', { level: 2 })

// 2순위: Label (폼 요소)
screen.getByLabelText('이메일')

// 3순위: Text (표시된 텍스트)
screen.getByText('환영합니다')

// 4순위: TestId (위 방법이 모두 안 될 때만)
screen.getByTestId('custom-element')
```

```typescript
// ❌ CSS 클래스/태그로 찾기 금지
container.querySelector('.btn-primary')
container.querySelector('div > span')
```

## 기본 구조

```typescript
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect, vi } from 'vitest'
import { LoginButton } from './LoginButton'

describe('LoginButton', () => {
  it('화면에 "로그인" 버튼이 렌더링된다', () => {
    render(<LoginButton onLogin={() => {}} />)
    expect(screen.getByRole('button', { name: '로그인' })).toBeInTheDocument()
  })
})
```

## 테스트 유형별 패턴

### 1. 렌더링 테스트

```typescript
it('필수 요소들이 렌더링된다', () => {
  render(<UserCard name="동균" email="test@test.com" />)

  expect(screen.getByText('동균')).toBeInTheDocument()
  expect(screen.getByText('test@test.com')).toBeInTheDocument()
})
```

### 2. Props 테스트

```typescript
it('disabled prop이 true면 버튼이 비활성화된다', () => {
  render(<SubmitButton disabled />)

  expect(screen.getByRole('button')).toBeDisabled()
})

it('variant="outline"이면 outline 스타일이 적용된다', () => {
  render(<Button variant="outline">클릭</Button>)

  expect(screen.getByRole('button')).toHaveClass('border')
})
```

### 3. 이벤트 테스트 (userEvent 권장)

```typescript
it('클릭 시 onSubmit이 호출된다', async () => {
  const user = userEvent.setup()
  const handleSubmit = vi.fn()

  render(<SubmitButton onSubmit={handleSubmit} />)
  await user.click(screen.getByRole('button', { name: '제출' }))

  expect(handleSubmit).toHaveBeenCalledTimes(1)
})

it('입력 필드에 텍스트를 입력한다', async () => {
  const user = userEvent.setup()
  const handleChange = vi.fn()

  render(<SearchInput onChange={handleChange} />)
  await user.type(screen.getByRole('textbox'), '검색어')

  expect(handleChange).toHaveBeenCalled()
})
```

```typescript
// ✅ userEvent 사용 (실제 사용자 동작 시뮬레이션)
await user.click(button)
await user.type(input, 'text')
await user.selectOptions(select, 'option1')

// ⚠️ fireEvent는 단순 이벤트 발생만 (userEvent 불가능 시)
fireEvent.change(input, { target: { value: 'text' } })
```

### 4. 조건부 렌더링 테스트

```typescript
it('로딩 중이면 스켈레톤을 표시한다', () => {
  render(<UserList isLoading />)

  expect(screen.getByTestId('skeleton')).toBeInTheDocument()
  expect(screen.queryByRole('list')).not.toBeInTheDocument()
})

it('데이터가 비어있으면 빈 상태 메시지를 표시한다', () => {
  render(<UserList items={[]} />)

  expect(screen.getByText('사용자가 없습니다')).toBeInTheDocument()
})
```

```typescript
// 요소가 없음을 확인할 때는 queryBy 사용
// ✅ queryBy — 없으면 null 반환
expect(screen.queryByText('에러')).not.toBeInTheDocument()

// ❌ getBy — 없으면 에러 throw (테스트 실패)
expect(screen.getByText('에러')).not.toBeInTheDocument()
```

### 5. 비동기 테스트

```typescript
it('데이터 로딩 후 목록을 표시한다', async () => {
  render(<UserList />)

  // waitFor: 조건이 충족될 때까지 대기
  await waitFor(() => {
    expect(screen.getByText('동균')).toBeInTheDocument()
  })
})

it('API 호출 후 결과를 표시한다', async () => {
  render(<SearchResults query="test" />)

  // findBy: getBy + waitFor 축약형
  const result = await screen.findByText('검색 결과')
  expect(result).toBeInTheDocument()
})
```

## Provider 감싸기

```typescript
// 테스트에 Provider가 필요한 경우
function renderWithProviders(ui: React.ReactElement) {
  return render(
    <QueryClientProvider client={new QueryClient()}>
      <ThemeProvider>{ui}</ThemeProvider>
    </QueryClientProvider>
  )
}

it('Provider 내에서 렌더링된다', () => {
  renderWithProviders(<Dashboard />)
  expect(screen.getByRole('main')).toBeInTheDocument()
})
```

## 점검 항목

- [ ] 셀렉터 우선순위를 지키는가 (getByRole > getByLabelText > getByText > getByTestId)
- [ ] CSS 클래스나 DOM 구조에 의존하지 않는가
- [ ] userEvent를 fireEvent보다 우선 사용하는가
- [ ] 요소 부재 확인 시 queryBy를 사용하는가 (getBy 아님)
- [ ] 비동기 동작에 waitFor 또는 findBy를 사용하는가
- [ ] 각 테스트가 독립적으로 실행 가능한가 (테스트 간 의존성 없음)
- [ ] 구현 세부사항이 아닌 사용자 관점에서 테스트하는가
