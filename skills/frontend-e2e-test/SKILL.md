---
name: frontend-e2e-test
description: Playwright E2E 테스트 작성 시 사용. Page Object Model, 시맨틱 셀렉터, 네트워크 대기, 인증 상태 관리, 실패 수집.
effort: medium
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# E2E 테스트 규칙 (Playwright)

## 대상

사용자 흐름 전체 검증 — 로그인, 폼 제출, 네비게이션, 권한별 접근 등

## 파일 구조

```
e2e/
├── fixtures/
│   └── auth.ts                 # 인증 상태 fixture
├── pages/
│   ├── LoginPage.ts            # Page Object
│   └── DashboardPage.ts
├── login.spec.ts               # 테스트 파일
├── dashboard.spec.ts
└── global-setup.ts             # 전역 설정
```

## Page Object Model (필수)

```typescript
// e2e/pages/LoginPage.ts
import { type Page, type Locator } from '@playwright/test'

export class LoginPage {
  private readonly emailInput: Locator
  private readonly passwordInput: Locator
  private readonly submitButton: Locator

  constructor(private readonly page: Page) {
    this.emailInput = page.getByLabel('이메일')
    this.passwordInput = page.getByLabel('비밀번호')
    this.submitButton = page.getByRole('button', { name: '로그인' })
  }

  async goto() {
    await this.page.goto('/login')
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email)
    await this.passwordInput.fill(password)
    await this.submitButton.click()
  }

  async expectError(message: string) {
    await expect(this.page.getByText(message)).toBeVisible()
  }
}
```

```typescript
// ✅ Page Object로 테스트 작성
test('로그인 성공', async ({ page }) => {
  const loginPage = new LoginPage(page)
  await loginPage.goto()
  await loginPage.login('test@test.com', 'password123')
  await expect(page).toHaveURL('/dashboard')
})

// ❌ 셀렉터를 테스트에 직접 하드코딩
test('로그인 성공', async ({ page }) => {
  await page.goto('/login')
  await page.getByLabel('이메일').fill('test@test.com')
  // ... 반복되는 셀렉터
})
```

## 셀렉터 우선순위

```typescript
// 1순위: Role (가장 안정적)
page.getByRole('button', { name: '제출' })
page.getByRole('heading', { level: 1 })
page.getByRole('navigation')

// 2순위: Label (폼 요소)
page.getByLabel('이메일')

// 3순위: Text
page.getByText('환영합니다')

// 4순위: Placeholder
page.getByPlaceholder('검색어를 입력하세요')

// 5순위: Test ID (위 방법이 모두 안 될 때만)
page.getByTestId('custom-widget')
```

```typescript
// ❌ CSS 셀렉터 금지
page.locator('.btn-primary')
page.locator('#submit-btn')
page.locator('div > form > button')
```

## 네트워크 대기

```typescript
// ✅ API 응답 대기 후 검증
const responsePromise = page.waitForResponse('/api/v1/members/me')
await page.getByRole('button', { name: '조회' }).click()
const response = await responsePromise
expect(response.status()).toBe(200)

// ✅ 네비게이션 대기
await page.waitForURL('/dashboard')

// ❌ 하드코딩된 대기 시간
await page.waitForTimeout(3000)
```

## 인증 상태 관리

```typescript
// e2e/global-setup.ts — 로그인 후 상태 저장
import { chromium } from '@playwright/test'

async function globalSetup() {
  const browser = await chromium.launch()
  const page = await browser.newPage()

  await page.goto('/login')
  await page.getByLabel('이메일').fill('test@test.com')
  await page.getByLabel('비밀번호').fill('password123')
  await page.getByRole('button', { name: '로그인' }).click()
  await page.waitForURL('/dashboard')

  // 인증 상태 저장
  await page.context().storageState({ path: '.auth/user.json' })
  await browser.close()
}

export default globalSetup
```

```typescript
// 인증된 상태로 테스트 실행
test.use({ storageState: '.auth/user.json' })

test('대시보드에 접근할 수 있다', async ({ page }) => {
  await page.goto('/dashboard')
  await expect(page.getByRole('heading', { name: '대시보드' })).toBeVisible()
})
```

## 실패 수집

```typescript
// playwright.config.ts
export default defineConfig({
  use: {
    // 실패 시 자동 스크린샷
    screenshot: 'only-on-failure',
    // 실패 시 trace 저장
    trace: 'on-first-retry',
    // 실패 시 비디오 저장
    video: 'on-first-retry',
  },
  retries: 1,  // 1회 재시도
})
```

## Flaky 테스트 방지

```typescript
// ✅ auto-waiting 활용 (Playwright 기본 동작)
await page.getByRole('button').click()  // 자동으로 visible + enabled 대기

// ✅ 명시적 대기가 필요한 경우
await expect(page.getByText('완료')).toBeVisible({ timeout: 10000 })

// ❌ 하드코딩 대기
await page.waitForTimeout(2000)

// ❌ 짧은 timeout (CI 환경에서 실패 가능)
await expect(page.getByText('완료')).toBeVisible({ timeout: 100 })
```

```typescript
// ✅ 독립적인 테스트 (순서 무관하게 실행 가능)
test('사용자를 생성한다', async ({ page }) => {
  // 테스트 자체에서 필요한 데이터 세팅
})

// ❌ 다른 테스트의 결과에 의존
test('생성된 사용자를 수정한다', async ({ page }) => {
  // 위 테스트에서 생성한 사용자에 의존 → flaky
})
```

## 점검 항목

- [ ] Page Object Model을 사용하는가
- [ ] 시맨틱 셀렉터를 우선 사용하는가 (CSS 셀렉터 금지)
- [ ] `waitForTimeout` 대신 `waitForResponse`, `waitForURL`, `toBeVisible` 등을 사용하는가
- [ ] 인증 상태를 `storageState`로 관리하는가
- [ ] 실패 시 스크린샷/trace를 수집하는 설정이 있는가
- [ ] 각 테스트가 독립적으로 실행 가능한가 (테스트 간 의존성 없음)
- [ ] CI 환경을 고려한 적절한 timeout을 설정하는가
