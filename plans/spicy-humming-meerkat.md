# PM 스킬에 phuryn 4개 컨셉 통합

## Context

현재 프로젝트 생성 프로세스(Phase 0~8)에 phuryn/pm-skills에서 4개 컨셉을 가져와 기존 흐름에 통합한다.
phuryn 스킬을 그대로 설치하지 않고, 아이디어만 가져와서 내 `spec.md` 단일 파일 패턴에 맞게 재설계한다.

| 컨셉 | 적용 위치 | 방식 |
|------|----------|------|
| prioritization (RICE) | Phase 1 | pm-requirements 스킬 확장 + pm.md 템플릿 수정 |
| pre-mortem | Phase 2.5 (신규) | 새 커맨드 `/pre-mortem` |
| test-scenarios | Phase 4.5 (신규) | 새 커맨드 `/test-scenarios` |
| dummy-dataset | Phase 5 | 새 스킬 `pm-dummy-dataset` |

## 수정/생성 파일 (6개)

### 1. pm-requirements 스킬 확장
**파일**: `~/.claude/skills/pm-requirements/SKILL.md`
**변경**: 92~112행의 기존 MoSCoW 섹션을 RICE + MoSCoW 통합으로 교체

RICE 점수 산출 공식: `(Reach × Impact × Confidence) / Effort`

| 요소 | 범위 |
|------|------|
| Reach | 1~10 (영향받는 사용자 규모) |
| Impact | 0.25 / 0.5 / 1 / 2 / 3 |
| Confidence | 50% / 80% / 100% |
| Effort | 인일(person-days) 0.5~20 |

RICE → MoSCoW 자동 매핑: Must(≥5.0), Should(2.0~4.9), Could(0.5~1.9), Won't(<0.5)

### 2. pm.md 에이전트 템플릿 수정
**파일**: `~/.claude/agents/pm.md`
**변경 2곳**:
- 기획 프로세스에 **4.5단계: 우선순위 산출** 삽입 (4단계 엣지케이스 점검과 5단계 휴리스틱 검증 사이)
- spec.md 템플릿 Part 1에 `## 구현 우선순위` 테이블 추가 (기능 요구사항 아래)

```markdown
## 구현 우선순위

| FR | 기능 | R | I | C | E | RICE | MoSCoW | 구현 순서 |
|----|------|---|---|---|---|------|--------|----------|
| FR-1 | [기능명] | _ | _ | _% | _ | _ | Must | 1 |
```

### 3. `/pre-mortem` 커맨드 생성
**파일**: `~/.claude/commands/pre-mortem.md`
**역할**: spec.md를 읽고 개발 리스크를 3가지로 분류, spec.md에 Part 4로 추가

- **Tigers** (진짜 위험): 구현을 지연/실패시킬 기술적 리스크
  - 복잡한 상태 관리, 성능 병목, 불명확한 외부 API 의존성
- **Paper Tigers** (과대평가): 어려워 보이지만 straightforward
  - 잘 문서화된 라이브러리, 기존 패턴 있는 작업
- **Elephants** (방 안의 코끼리): 아무도 언급 안 했지만 대응 필요
  - 배포 전략, 모니터링, 접근성, 테스트 커버리지

프로세스: spec.md 읽기 → 리스크 식별 → AskUserQuestion 인터뷰 → Part 4 추가

출력 형식:
```markdown
# Part 4. 개발 리스크 분석 (Pre-mortem)

## Tigers (진짜 위험)
| # | FR | 리스크 | 영향도 | 대응 전략 |
|---|-----|--------|-------|----------|

## Paper Tigers (과대평가된 위험)
| # | FR | 우려 사항 | 실제 난이도 | 근거 |
|---|-----|----------|-----------|------|

## Elephants (방 안의 코끼리)
| # | 영역 | 미대응 이슈 | 영향도 | 권장 대응 시점 |
|---|------|-----------|-------|-------------|
```

### 4. `/test-scenarios` 커맨드 생성
**파일**: `~/.claude/commands/test-scenarios.md`
**역할**: spec.md Part 2(유저 플로우) + Part 3(에러 시나리오)를 읽어 테스트 계획 생성

소스 매핑:
| spec.md 소스 | 테스트 유형 | 접두어 |
|-------------|-----------|-------|
| Primary Flow | Happy Path E2E | HP- |
| Alternative Flow | Alternative E2E | AF- |
| Error Flow | Error Path E2E | EF- |
| 데이터 에러 | Validation Test | VT- |
| 네트워크 에러 | Network Error Test | NT- |
| 사용자 행동 에러 | User Behavior Test | UB- |
| 엣지케이스 | Edge Case Test | EC- |

우선순위: P0(필수: Primary Flow + Must FR), P1(중요: Error Flow + Should FR), P2(권장: Alternative + Edge)

**출력**: `docs/specs/[기능명]/test-plan.md` (별도 파일, spec.md에는 넣지 않음 — 길이 문제)

### 5. `pm-dummy-dataset` 스킬 생성
**파일**: `~/.claude/skills/pm-dummy-dataset/SKILL.md`
**역할**: spec.md의 엔티티/데이터 모델을 읽어 시드 데이터 생성

데이터 생성 원칙:
- 한국어 이름/주소/전화번호 (현실적 데이터)
- 정상 10~20건 + 경계값 2~3건 + 빈 데이터 1건 + 에러 유발 2~3건
- UUID v4, FK 정합성 보장

**출력 2개**:
- `docs/specs/[기능명]/seed-data.ts` — TypeScript 목 데이터
- `docs/specs/[기능명]/seed-data.sql` — Supabase PostgreSQL INSERT문

### 6. CLAUDE.md Phase 목록 업데이트
**파일**: `~/.claude/CLAUDE.md`

```
Phase 0:   브레인스토밍 → brainstorming 스킬
Phase 1:   기획 → pm 에이전트 (PRD + RICE 우선순위, 유저플로우, 에러시나리오)
Phase 2:   기획 검증 → /spec-review 커맨드
Phase 2.5: 리스크 분석 → /pre-mortem 커맨드
Phase 3:   UI 설계 → Pencil MCP
Phase 4:   구현 계획 → writing-plans 스킬
Phase 4.5: 테스트 계획 → /test-scenarios 커맨드
Phase 5:   Foundation → Lead 직접 (프레임워크, DB, 인증, pm-dummy-dataset 시딩)
Phase 6:   병렬 개발 → 팀 에이전트 (worktree)
Phase 7:   검증 루프 → reviewer + test + Playwright (test-plan.md 기반)
Phase 8:   기록 → docs/conversations/
```

## 구현 순서

1. `pm-requirements/SKILL.md` — MoSCoW → RICE+MoSCoW 교체
2. `agents/pm.md` — 4.5단계 추가 + 템플릿에 우선순위 테이블
3. `commands/pre-mortem.md` — 새 커맨드 생성
4. `commands/test-scenarios.md` — 새 커맨드 생성
5. `skills/pm-dummy-dataset/SKILL.md` — 새 스킬 생성
6. `CLAUDE.md` — Phase 목록 업데이트

## 검증

각 파일 생성/수정 후:
- pm-requirements: RICE 테이블과 MoSCoW 매핑 로직이 명확한지 확인
- pm.md: spec.md 템플릿에 구현 우선순위 섹션이 올바르게 위치하는지 확인
- pre-mortem: spec-review.md와 동일한 파일 탐색 패턴 사용 확인
- test-scenarios: 소스 매핑이 spec.md Part 2/3 구조와 일치하는지 확인
- dummy-dataset: 기존 pm-* 스킬 frontmatter 패턴과 일치하는지 확인
- CLAUDE.md: Phase 번호가 정확한지 확인
