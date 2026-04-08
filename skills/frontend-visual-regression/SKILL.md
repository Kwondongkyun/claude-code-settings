---
name: frontend-visual-regression
description: Playwright 시각적 회귀 테스트 작성 시 사용. 스크린샷 비교, 반응형 뷰포트, 동적 콘텐츠 마스킹, 베이스라인 관리.
effort: medium
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# 시각적 회귀 테스트 규칙 (Playwright)

## 대상

UI가 의도치 않게 변경되었는지 스크린샷 비교로 감지. 레이아웃 변경, 색상 변경, 요소 위치 이탈 등.

## 파일 구조

```
e2e/
├── visual/
│   ├── login.visual.spec.ts        # 시각적 테스트 파일
│   └── dashboard.visual.spec.ts
├── visual.snapshots/                # 기준 스크린샷 (자동 생성)
│   ├── login-page-desktop.png
│   └── login-page-mobile.png
```

## 기본 사용법

```typescript
import { test, expect } from '@playwright/test'

test('로그인 페이지 스크린샷', async ({ page }) => {
  await page.goto('/login')

  // 페이지 안정화 대기
  await page.waitForLoadState('networkidle')

  await expect(page).toHaveScreenshot('login-page.png')
})
```

## 반응형 뷰포트 테스트

```typescript
const viewports = [
  { name: 'mobile', width: 375, height: 812 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'desktop', width: 1440, height: 900 },
]

for (const viewport of viewports) {
  test(`로그인 페이지 - ${viewport.name}`, async ({ page }) => {
    await page.setViewportSize({ width: viewport.width, height: viewport.height })
    await page.goto('/login')
    await page.waitForLoadState('networkidle')

    await expect(page).toHaveScreenshot(`login-${viewport.name}.png`)
  })
}
```

## 동적 콘텐츠 마스킹

날짜, 시간, 랜덤 데이터 등 매번 달라지는 요소는 마스킹한다.

```typescript
// ✅ 동적 요소 마스킹
await expect(page).toHaveScreenshot('dashboard.png', {
  mask: [
    page.getByTestId('current-time'),
    page.getByTestId('random-avatar'),
    page.locator('.timestamp'),
  ],
})

// ✅ 특정 영역만 스크린샷
const header = page.getByRole('banner')
await expect(header).toHaveScreenshot('header.png')
```

## 비교 임계값

```typescript
// ✅ 1% 이하 차이만 허용 (기본 권장)
await expect(page).toHaveScreenshot('page.png', {
  maxDiffPixelRatio: 0.01,
})

// ✅ 폰트 렌더링 차이가 큰 환경 (CI vs 로컬)
await expect(page).toHaveScreenshot('page.png', {
  maxDiffPixelRatio: 0.02,
  threshold: 0.3,  // 픽셀 색상 차이 허용치
})

// ❌ 임계값 없이 비교 (사소한 렌더링 차이로 실패)
await expect(page).toHaveScreenshot('page.png', {
  maxDiffPixelRatio: 0,
})
```

## 애니메이션 처리

```typescript
// playwright.config.ts — 전역 설정
export default defineConfig({
  use: {
    // ✅ 애니메이션 비활성화 (스크린샷 안정성)
    actionTimeout: 10000,
  },
})
```

```typescript
// ✅ 테스트 내에서 애니메이션 비활성화
test('카드 컴포넌트', async ({ page }) => {
  await page.goto('/cards')

  // CSS 애니메이션/트랜지션 비활성화
  await page.addStyleTag({
    content: `
      *, *::before, *::after {
        animation-duration: 0s !important;
        transition-duration: 0s !important;
      }
    `,
  })

  await expect(page).toHaveScreenshot('cards.png')
})
```

## 기준 스크린샷(Baseline) 관리

```bash
# 기준 스크린샷 최초 생성 / 업데이트
npx playwright test --update-snapshots

# 특정 파일만 업데이트
npx playwright test visual/login.visual.spec.ts --update-snapshots
```

```typescript
// ❌ 스크린샷 파일을 .gitignore에 넣지 않음 (팀원과 공유해야 함)
// ✅ visual.snapshots/ 디렉토리를 git에 포함
```

## 컴포넌트 단위 스크린샷

```typescript
test('버튼 컴포넌트 변형', async ({ page }) => {
  await page.goto('/storybook/button')

  // 특정 요소만 스크린샷
  const primaryBtn = page.getByRole('button', { name: 'Primary' })
  await expect(primaryBtn).toHaveScreenshot('button-primary.png')

  const outlineBtn = page.getByRole('button', { name: 'Outline' })
  await expect(outlineBtn).toHaveScreenshot('button-outline.png')
})
```

## 다크모드 테스트

```typescript
test('로그인 페이지 - 다크모드', async ({ page }) => {
  // 다크모드 설정
  await page.emulateMedia({ colorScheme: 'dark' })
  await page.goto('/login')

  await expect(page).toHaveScreenshot('login-dark.png')
})

test('로그인 페이지 - 라이트모드', async ({ page }) => {
  await page.emulateMedia({ colorScheme: 'light' })
  await page.goto('/login')

  await expect(page).toHaveScreenshot('login-light.png')
})
```

## 점검 항목

- [ ] 동적 콘텐츠(날짜, 시간, 랜덤 값)를 마스킹하는가
- [ ] 반응형 뷰포트(모바일, 태블릿, 데스크톱)별로 테스트하는가
- [ ] `maxDiffPixelRatio`를 0.01~0.02로 설정하는가
- [ ] 애니메이션/트랜지션을 비활성화하는가
- [ ] 기준 스크린샷을 git에 포함하는가 (.gitignore 제외)
- [ ] `networkidle` 등으로 페이지 안정화를 대기하는가
- [ ] CI와 로컬의 렌더링 차이를 고려한 threshold를 설정하는가
