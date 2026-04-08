---
description: Sprint Contract 생성 — 코딩 전 Generator/Evaluator 간 합격 기준 합의
argument-hint: <spec-folder-or-file>
effort: high
---

한국어로 응답하세요.

## 목적

코딩 시작 전, **"뭘 만들면 합격이고, 뭘 못 만들면 불합격인지"** 합의 문서를 만든다.
이 문서가 iteration-evaluator 에이전트의 채점 기준표가 된다.

## 파일 탐색

- `$ARGUMENTS`가 폴더 경로 → 해당 폴더의 `spec.md` 읽기
- `$ARGUMENTS`가 파일 경로 → 해당 파일 읽기
- `$ARGUMENTS` 없음 → `docs/specs/` 탐색 → AskUserQuestion으로 선택

spec.md가 없으면 "spec.md가 필요합니다. pm 에이전트로 먼저 기획하세요." 안내 후 종료.

## 실행 순서

### STEP 1: 스펙 분석

spec.md에서 추출할 것:
1. **FR (기능 요구사항)** 목록 — 구현해야 할 기능 전부
2. **유저 플로우** — Primary Flow, Alternative Flow
3. **에러 시나리오** — Error Flow, 엣지케이스
4. **비기능 요구사항** — 성능, 접근성, 반응형 등

### STEP 2: 합격 기준 작성

각 FR에 대해 **4축**으로 테스트 가능한 합격 기준을 작성한다.

#### 기능성 (가중치 40%) — "버튼이 작동하는가"

각 FR의 핵심 동작을 **Playwright로 검증 가능한** 문장으로 작성:
- "X 버튼을 클릭하면 Y 페이지로 이동한다"
- "폼에 A를 입력하고 제출하면 B가 표시된다"
- "API 호출 시 200 응답이 오고 데이터가 렌더링된다"

검증 방법 예시:
```
Playwright: page.click('로그인') → expect(page).toHaveURL('/dashboard')
Playwright: page.fill('이메일', 'test@test.com') → page.click('제출') → expect('성공').toBeVisible()
```

#### 디자인 품질 (가중치 25%) — "AI가 약한 영역"

AI가 특히 약한 영역에 집중:
- "375px 뷰포트에서 가로 스크롤이 없다"
- "768px, 1440px에서 레이아웃이 자연스럽다"
- "텍스트가 잘리거나 겹치지 않는다"
- "색상/폰트가 일관적이다 (AI slop 패턴 없음)"
- "시각적 계층 구조가 명확하다"

검증 방법: Playwright viewport 변경 + 스크린샷

#### 코드 품질 (가중치 20%) — "AI가 잘하는 영역"

- "TypeScript 컴파일 에러 0개 (`tsc --noEmit`)"
- "lint 에러 0개"
- "콘솔 에러 0개"
- "React hydration 에러 0개"

검증 방법: CLI 명령어 실행

#### 완성도 (가중치 15%) — "마무리"

- "데이터 없을 때 Empty 상태가 표시된다"
- "로딩 중 Loading 상태가 표시된다"
- "에러 발생 시 Error 상태가 표시된다 (흰 화면 아님)"
- "없는 경로 접근 시 404 페이지가 표시된다"
- spec.md의 에러 시나리오에서 명시한 각 에러 케이스

검증 방법: Playwright로 해당 상태 유도 + 스크린샷

### STEP 3: 자동화 가능 여부 태깅

각 기준에 대해:
- **Yes**: Playwright MCP 또는 CLI로 자동 검증 가능 → iteration-evaluator가 자동으로 Pass/Fail 판정
- **No**: 사람의 눈으로 확인 필요 (시각적 판단, 주관적 품질) → iteration-evaluator가 스크린샷 첨부 후 판단

### STEP 4: 사용자 확인

작성된 기준표를 사용자에게 보여주고 AskUserQuestion으로 확인:
- "이 기준으로 진행할까요?"
- "추가하거나 수정할 기준이 있나요?"
- "가중치를 조정할까요? (기본: 기능 40% / 디자인 25% / 코드 20% / 완성도 15%)"

### STEP 5: contract.md 저장

`docs/specs/[기능명]/contract.md`에 저장한다.
템플릿: `~/.claude/templates/contract.md`

## 출력 예시

```markdown
# Sprint Contract: 로그인

> 합의일: 2026-03-29
> 소스: docs/specs/login/spec.md
> Pass 기준: 가중 점수 80점 이상 + Critical 0개

---

## 기능성 (40%)

| # | 합격 기준 | 검증 방법 | 자동화 |
|---|----------|----------|--------|
| F-1 | 이메일+비밀번호 입력 후 로그인 버튼 클릭 → 대시보드 이동 | Playwright: fill → click → toHaveURL('/dashboard') | Yes |
| F-2 | 잘못된 비밀번호 → "비밀번호가 올바르지 않습니다" 에러 표시 | Playwright: fill → click → expect('비밀번호가').toBeVisible() | Yes |
| F-3 | 소셜 로그인(Google) 버튼이 존재하고 클릭 가능 | Playwright: getByRole('button', {name: 'Google'}).isEnabled() | Yes |
| F-4 | 로그인 후 토큰이 localStorage에 저장됨 | Playwright: evaluate → localStorage.getItem('token') !== null | Yes |

## 디자인 품질 (25%)

| # | 합격 기준 | 검증 방법 | 자동화 |
|---|----------|----------|--------|
| D-1 | 375px에서 가로 스크롤 없음 | Playwright: viewport(375) → scrollWidth <= clientWidth | Yes |
| D-2 | 입력 필드와 버튼이 시각적으로 그룹핑 | 스크린샷 확인 | No |
| D-3 | 에러 메시지가 빨간색 계열로 표시 | 스크린샷 확인 | No |

## 코드 품질 (20%)

| # | 합격 기준 | 검증 방법 | 자동화 |
|---|----------|----------|--------|
| C-1 | tsc --noEmit 에러 0개 | CLI: npx tsc --noEmit | Yes |
| C-2 | 콘솔 에러 0개 | Playwright: page.on('console', error) | Yes |

## 완성도 (15%)

| # | 합격 기준 | 검증 방법 | 자동화 |
|---|----------|----------|--------|
| P-1 | 빈 이메일로 제출 시 "이메일을 입력하세요" 표시 | Playwright: click submit → expect error | Yes |
| P-2 | 네트워크 오류 시 "다시 시도하세요" 메시지 | Playwright: route.abort → expect error | Yes |
| P-3 | 로딩 중 버튼 비활성화 + 스피너 표시 | Playwright: click → expect button disabled | Yes |
```

## 주의사항

- 기준은 **테스트 가능해야** 한다. "좋은 UX" 같은 모호한 기준 금지. "버튼 클릭 → 결과 확인" 수준으로 구체적으로.
- spec.md에 없는 기능을 기준에 넣지 마라. spec.md 범위 안에서만.
- 자동화 가능한 기준을 최대화하라. iteration-evaluator가 자동으로 검증할 수 있을수록 좋다.
- 기준 개수는 FR 규모에 비례. 소규모(~5 FR): 10-15개, 중규모(~15 FR): 20-30개.
