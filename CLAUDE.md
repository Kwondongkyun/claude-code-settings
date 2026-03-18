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
Phase 0: 브레인스토밍 → brainstorming 스킬
Phase 1: 기획 → pm 에이전트 (PRD, 유저플로우, IA, 에러시나리오)
Phase 2: 기획 검증 → spec-review 스킬
Phase 3: UI 설계 → Pencil MCP
Phase 4: 구현 계획 → writing-plans 스킬
Phase 5: Foundation → Lead 직접 (프레임워크, DB, 인증)
Phase 6: 병렬 개발 → 팀 에이전트 (worktree)
Phase 7: 검증 루프 → reviewer + test + Playwright
Phase 8: 기록 → docs/conversations/
```
- 각 Phase는 독립적이며, Phase 전환 시 반드시 사용자에게 확인한다.
- Phase 간 자동 호출 금지 (brainstorming→writing-plans, writing-plans→executing-plans 등).

## 컨텍스트 관리
- 세션 시작 시 plan.md, progress.md, memory.md, findings.md가 있으면 읽고 현재 상황을 파악한다.
- 작업 중 계획 변경 시 plan.md, 진행 상태 변경 시 progress.md, 중요 결정 시 memory.md, 조사/발견 시 findings.md를 업데이트한다.
- compact 복구 리마인더가 오면 위 파일들을 반드시 읽는다.

## Defaults
- Prefer editing existing files over creating new ones.
- Don't create documentation files (README, etc.) unless asked.
- Stop after 3 failed attempts and reassess the approach.
