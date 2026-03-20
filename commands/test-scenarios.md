---
description: spec.md 기반 테스트 시나리오 생성 — 유저 플로우 + 에러 시나리오 → 테스트 계획
argument-hint: <spec-folder-or-file>
---

**Always respond in Korean (한국어).**

## Spec File Discovery

1. `$ARGUMENTS`가 **폴더 경로**이면 해당 폴더 내 `spec.md`를 읽는다.
2. `$ARGUMENTS`가 **파일 경로**이면 해당 파일을 읽는다.
3. `$ARGUMENTS`가 없으면 `docs/specs/` 디렉토리를 자동 탐색한다:
   - `docs/specs/` 하위의 **기능 폴더 목록**을 검색한다.
   - AskUserQuestion으로 대상 **폴더**를 선택받는다.
   - 선택된 폴더 내 `spec.md`를 읽는다.
4. `docs/specs/` 디렉토리도 없고 `$ARGUMENTS`도 없으면, 경로를 직접 입력받는다.

spec.md를 읽은 후 아래 워크플로우를 진행한다.

## 소스 매핑 규칙

spec.md의 각 섹션에서 테스트 케이스를 추출하는 매핑:

| spec.md 소스 | 테스트 유형 | 접두어 | 우선순위 기본값 |
|-------------|-----------|-------|-------------|
| Part 2 > Primary Flow | Happy Path E2E | HP- | P0 |
| Part 2 > Alternative Flow | Alternative E2E | AF- | P2 |
| Part 2 > Error Flow | Error Path E2E | EF- | P1 |
| Part 3 > 데이터 에러 | Validation Test | VT- | P1 |
| Part 3 > 네트워크 에러 | Network Error Test | NT- | P1 |
| Part 3 > 사용자 행동 에러 | User Behavior Test | UB- | P2 |
| Part 3 > 서버/인증 에러 | Auth/Server Test | AS- | P1 |
| Part 1 > 엣지케이스 | Edge Case Test | EC- | P2 |
| Part 1 > 비기능 요구사항 | Non-functional Test | NF- | P2 |

## 우선순위 기준

| 우선순위 | 기준 | Phase 7에서 |
|---------|------|------------|
| **P0** (필수) | Primary Flow + Must FR의 핵심 동작 | 반드시 작성 |
| **P1** (중요) | Error Flow + Should FR + 인증/네트워크 에러 | 가급적 작성 |
| **P2** (권장) | Alternative Flow + Could FR + 엣지케이스 + 사용자 행동 | 여유 시 작성 |

구현 우선순위 테이블이 있으면 (RICE/MoSCoW) FR의 MoSCoW 등급을 반영한다:
- Must FR → 관련 테스트 P0 승격
- Won't FR → 테스트 제외

## Workflow

### STEP 1: 테스트 대상 식별

spec.md를 정독하고, 소스 매핑 규칙에 따라 모든 테스트 대상을 추출한다.

**추출 시 확인:**
- Part 2의 모든 Flow가 커버되는가?
- Part 3의 모든 에러 시나리오가 매핑되는가?
- Part 1의 엣지케이스 중 테스트 가능한 항목이 누락되지 않았는가?
- Part 4(Pre-mortem)가 있으면 Tiger의 대응 전략과 관련된 검증 테스트를 추가한다.

### STEP 2: 확인 질문

AskUserQuestion으로 테스트 범위를 확인한다:
- "인증이 필요한 테스트의 경우, 테스트용 계정 생성 방식은?" (Supabase seed / mock)
- "외부 API 호출이 있는 테스트는 MSW로 모킹하나요?"
- "P0만 먼저 생성하고 P1/P2는 나중에 추가할까요, 전체를 한번에 생성할까요?"
- 프로젝트 특성에 맞는 구체적 질문 2~3개

### STEP 3: 테스트 시나리오 작성

각 테스트 케이스를 아래 형식으로 작성한다:

```markdown
### [접두어]-[번호]: [테스트명]

- **출처**: spec.md [Part/Section/항목 번호]
- **유형**: E2E / Component / API
- **우선순위**: P0 / P1 / P2
- **사전 조건**: [테스트 시작 전 필요한 상태]
- **테스트 단계**:
  1. [사용자 행동] → [기대 결과]
  2. [사용자 행동] → [기대 결과]
- **검증 항목**:
  - [ ] [구체적 assertion]
  - [ ] [구체적 assertion]
- **Playwright 힌트**: `page.goto(...)`, `expect(locator).toBeVisible()`
```

### STEP 4: 파일 생성

`docs/specs/[기능명]/test-plan.md`에 아래 구조로 저장한다:

```markdown
# Test Plan: [기능명]

> 생성일: YYYY-MM-DD
> 소스: docs/specs/[기능명]/spec.md
> 총 테스트 케이스: N개 (P0: _개, P1: _개, P2: _개)

---

## 커버리지 매트릭스

| spec.md 항목 | 테스트 케이스 | 커버 여부 |
|-------------|-------------|----------|
| Primary Flow | HP-1, HP-2 | O |
| AF-1 | AF-1 | O |
| EF-1 | EF-1 | O |
| D-1 필수값 미입력 | VT-1 | O |
| ... | ... | ... |

---

## P0 테스트 (필수)

### HP-1: [테스트명]
...

---

## P1 테스트 (중요)

### EF-1: [테스트명]
...

---

## P2 테스트 (권장)

### EC-1: [테스트명]
...

---

## Phase 7 Playwright 매핑

| 테스트 ID | 파일 경로 (권장) | 설명 |
|----------|----------------|------|
| HP-1 | e2e/[기능명]/happy-path.spec.ts | [한줄 설명] |
| EF-1 | e2e/[기능명]/error-flow.spec.ts | [한줄 설명] |
| VT-1 | e2e/[기능명]/validation.spec.ts | [한줄 설명] |
```

완료 후 생성 요약을 출력한다:
- 총 테스트 케이스 수 (P0/P1/P2별)
- 커버리지 비율 (매핑된 spec 항목 / 전체 spec 항목)
- Phase 7에서 `/test-scenarios`로 생성된 `test-plan.md`를 참고하여 Playwright 테스트를 작성하면 된다는 안내

**Reminder: All responses must be in Korean (한국어).**
