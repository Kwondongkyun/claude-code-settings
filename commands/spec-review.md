---
description: Deep-dive spec review — interview-driven issue discovery and structured decision-making
argument-hint: <spec-folder-or-file>
---

**Always respond in Korean (한국어).**

## Spec File Discovery

1. `$ARGUMENTS`가 **폴더 경로**이면 해당 폴더 내 모든 `.md` 파일을 읽는다.
2. `$ARGUMENTS`가 **파일 경로**이면 해당 파일을 읽고, 같은 폴더 내 다른 `.md` 파일도 컨텍스트로 함께 읽는다.
3. `$ARGUMENTS`가 없으면 `docs/specs/` 디렉토리를 자동 탐색한다:
   - `docs/specs/` 하위의 **기능 폴더 목록**을 검색한다.
   - AskUserQuestion으로 리뷰할 **폴더**를 선택받는다.
   - 예: `docs/specs/login/`, `docs/specs/sign-up/` 등
   - 선택된 폴더 내 모든 `.md` 파일을 읽는다.
4. `docs/specs/` 디렉토리도 없고 `$ARGUMENTS`도 없으면, 스펙 폴더 또는 파일 경로를 직접 입력받는다.

### 문서 역할 분류

읽은 파일들을 아래 기준으로 분류한다:
- **메인 문서**: PRD (`prd.md` 또는 파일명에 `requirements`/`prd` 포함) — 리뷰의 중심축
- **컨텍스트 문서**: 유저플로우, IA, 에러시나리오 등 나머지 — 교차 검증용

메인 문서가 없으면 가장 큰 파일을 메인으로 사용한다.
모든 문서를 읽은 후 아래 워크플로우를 진행한다.

# Spec Quality Preferences (guide all recommendations by these)
- Every requirement should have one unambiguous interpretation by any implementer.
- Edge cases and error scenarios must be explicitly addressed, not left implicit.
- Define what's OUT of scope as clearly as what's in scope.
- Favor concrete examples over abstract descriptions.
- If a decision was made, document WHY — not just WHAT.

# Workflow

## STEP 1: Spec Interview
Using AskUserQuestion, interview me in depth across all dimensions: requirements clarity, architecture, technical feasibility, UI & UX, edge cases, constraints, and tradeoffs.

**Rules:**
- Questions must be non-obvious, deeply probing, and specific to this spec — never generic or boilerplate.
- Skip dimensions the spec already covers well; focus on gaps.
- **컨텍스트 문서(유저플로우/IA/에러시나리오)와 PRD를 교차 검증**하여, 문서 간 불일치나 누락을 질문에 반영한다.
  - 예: PRD에 "로그인 실패 시 3회 제한"이 있는데 에러시나리오에 해당 케이스가 없으면 질문한다.
  - 예: 유저플로우에 있는 화면이 IA에 빠져있으면 질문한다.
- Number each question (Q1, Q2, Q3...).
- Build on previous answers — never repeat covered ground.
- If my answer is vague, push back and dig deeper.
- Do NOT assume my priorities on timeline or scale — ask.
- Continue until all dimensions are sufficiently covered.

## STEP 2: Issue Review
Synthesize interview findings into issues, organized by section:
1) Requirements Clarity — ambiguous language, multiple interpretations, missing acceptance criteria
2) Completeness — missing edge cases, error scenarios, boundary conditions, undefined behaviors
3) Architecture & Feasibility — technical risks, unrealistic constraints, unresolved dependencies
4) Scope & Boundaries — unclear in/out of scope, scope creep risks, undefined limits
5) UX & User Flows (if applicable) — incomplete flows, missing error/loading/empty states
6) Cross-document Consistency — PRD와 컨텍스트 문서 간 불일치, 누락, 모순 (컨텍스트 문서가 있을 때만)

**Issue format:**
- Number issues (1-1, 1-2 = section 1, issue 1 and 2).
- Describe the problem concretely with spec references.
- Present 2-3 options with LETTERS (A, B, C). Include "do nothing" where reasonable.
- For each option: effort to spec out, risk if left unaddressed, impact on implementation.
- **Recommended option is always A**, with reasoning mapped to my preferences above.
- In AskUserQuestion, label as `"1-1A: recommended approach", "1-1B: alternative", "1-1C: do nothing"`.

**Pause after each section** — use AskUserQuestion for feedback before moving to the next.

## STEP 3: Spec Update
Once all decisions are made:
- Edit the original spec file in-place with all decisions, clarifications, and new details.
- Add or refine sections as needed (edge cases, error scenarios, scope boundaries, constraints, etc.).
- Mark open items with `> [!WARNING] OPEN ITEM:` callouts.
- Do NOT remove existing content unless explicitly agreed.
- Provide a brief summary of what changed.

**Reminder: All responses must be in Korean (한국어).**
