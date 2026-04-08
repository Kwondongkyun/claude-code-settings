# CLAUDE.md
Always respond in Korean (한국어).

## Planning
- Propose a brief plan before non-trivial work (new features, multi-file changes, architectural decisions).
- Trivial work (typos, obvious fixes, single-line changes) — just do it.
- If multiple reasonable approaches exist, present them with tradeoffs. Don't pick silently.

## Communication
- Be direct and specific. No hedging on technical recommendations.
- If uncertain, say so and ask — don't guess.
- When recommending: state what, why, and what could go wrong.

## 프로젝트 생성 프로세스
```
Phase 0:   브레인스토밍 → brainstorming 스킬
Phase 1:   기획 → pm 에이전트 (PRD + RICE 우선순위, 유저플로우, 에러시나리오)
Phase 2:   기획 검증 → /spec-review 커맨드
Phase 2.5: 리스크 분석 → /pre-mortem 커맨드
Phase 3:   UI 설계 → Pencil MCP (비활성화 시 "Pencil 앱을 실행해주세요" 안내 후 대기)
Phase 4:   구현 계획 → writing-plans 스킬
Phase 4.5: 테스트 계획 → /test-scenarios 커맨드
Phase 4.7: Sprint Contract → /sprint-contract 커맨드 (iteration-evaluator 채점 기준 합의)
Phase 5:   Foundation → Lead 직접 (프레임워크, DB, 인증, pm-dummy-dataset 시딩)
Phase 6:   병렬 개발 → 팀 에이전트 (worktree, 규모 무관 항상 분기)
Phase 7:   검증 루프 → iteration-evaluator (Playwright 앱 테스트 + 4축 점수)
                       + handoff.md (iteration 간 인수인계)
                       + /pivot-check (점수 정체 시 방향 전환)
                       + reviewer + test (기존 유지)
Phase 8:   기록 → /wrap (session-wrap: 문서 업데이트 + 학습 추출 + 다음 할 일)
                       + handoff.md 업데이트 (다음 세션 인수인계)
                       + score-history.jsonl 보존 (평가 점수 이력)
```
- 각 Phase는 독립적이며, Phase 전환 시 반드시 사용자에게 확인한다.
- Phase 간 자동 호출 금지 (brainstorming→writing-plans, writing-plans→executing-plans 등).

## 컨텍스트 관리
- 세션 시작 시 handoff.md가 있으면 **최우선** 읽기. handoff.md 안의 컨텍스트 파일 링크를 따라 plan.md, progress.md, memory.md, findings.md를 순서대로 읽는다.
- compact 복구 리마인더가 오면 위 파일들을 반드시 읽는다.

### 파일별 업데이트 규칙 (언제, 무엇을)

**progress.md**
- Edit/Write 도구로 코드 수정을 시작하기 전: "진행 중" 섹션에 현재 작업 한 줄 기록
- 작업 단위 완료 시: "진행 중" → "완료"로 이동
- 블로커 발생 즉시: "이슈/블로커" 섹션에 추가

**plan.md**
- 접근 방식이 바뀔 때: "접근 방식" 섹션 업데이트
- 작업 항목 완료 시: 체크박스 체크
- 새 결정사항 생길 때: "결정사항" 섹션에 추가

**findings.md**
- 예상과 다른 동작을 발견했을 때 즉시 추가
- 참고한 외부 자료가 있을 때 링크 추가

**memory.md**
- 프로젝트 방향이 바뀌는 중요 결정이 있을 때만 업데이트 (자주 쓰지 않음)

## Defaults
- Prefer editing existing files over creating new ones.
- Don't create documentation files (README, etc.) unless asked.
- Stop after 3 failed attempts and reassess the approach.
