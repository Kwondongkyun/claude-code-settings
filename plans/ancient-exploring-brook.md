# Frontend Test 스킬 6개 + 서브에이전트 생성 계획

## Context

Ralph Loop 파이프라인 `pm → spec-review → frontend → frontend-test → frontend-reviewer → eval-all`에서
`frontend-test` 단계를 담당할 스킬과 서브에이전트가 없다.
6개 테스트 스킬을 만들고, 이를 묶는 `frontend-test` 서브에이전트를 생성한다.

## 결정사항
- **스킬 깊이**: 기존 수준 (약 150줄, 규칙 + ✅/❌ 코드 예시 + 점검 항목)
- **서브에이전트 모델**: opus

## 기존 패턴

- 스킬 위치: `~/.claude/skills/[스킬명]/SKILL.md`
- 에이전트 위치: `~/.claude/agents/[에이전트명].md`
- YAML frontmatter: `name`, `description`, `allowed-tools`
- 내용 구조: 제목 → 코드 예시 (✅/❌ 패턴) → 점검 항목 리스트

## 생성할 파일 (7개)

### 스킬 6개

| # | 파일 경로 | 핵심 내용 |
|---|----------|----------|
| 1 | `~/.claude/skills/frontend-unit-test/SKILL.md` | Vitest 단위 테스트 — AAA 패턴, vi.fn/vi.mock, 커스텀 훅 renderHook |
| 2 | `~/.claude/skills/frontend-component-test/SKILL.md` | Vitest + RTL 컴포넌트 테스트 — 셀렉터 우선순위, 렌더링/이벤트/상태/비동기 테스트 |
| 3 | `~/.claude/skills/frontend-api-mock-test/SKILL.md` | MSW + Vitest API 모킹 — setupServer, handlers, 인터셉터 테스트, 에러 시나리오 |
| 4 | `~/.claude/skills/frontend-e2e-test/SKILL.md` | Playwright E2E — Page Object Model, 시맨틱 셀렉터, 네트워크 대기, 실패 수집 |
| 5 | `~/.claude/skills/frontend-visual-regression/SKILL.md` | Playwright 스크린샷 비교 — baseline 관리, 반응형 뷰포트, 동적 콘텐츠 마스킹 |
| 6 | `~/.claude/skills/frontend-tdd-workflow/SKILL.md` | TDD Red-Green-Refactor — 인터페이스 먼저, 한 번에 하나의 테스트, 커버리지 80% |

### 서브에이전트 1개

| # | 파일 경로 | 역할 |
|---|----------|------|
| 7 | `~/.claude/agents/frontend-test.md` | 6개 스킬을 모두 활용하는 프론트엔드 테스트 전문가 에이전트 |

## 각 스킬 상세 설계

### 1. `frontend-unit-test`
- **allowed-tools**: Read, Write, Edit, Bash, Glob, Grep
- **내용**:
  - 테스트 파일 네이밍: `*.test.ts` (같은 디렉토리)
  - AAA 패턴 (Arrange-Act-Assert) 필수 구조
  - `vi.fn()` 스파이 함수 사용법
  - `vi.mock()` 모듈 모킹 패턴 (외부 의존성만)
  - `beforeEach`에서 `vi.clearAllMocks()` 필수
  - 커스텀 훅 테스트: `renderHook()` + `act()` 패턴
  - ✅/❌ 코드 예시 포함

### 2. `frontend-component-test`
- **allowed-tools**: Read, Write, Edit, Bash, Glob, Grep
- **내용**:
  - 테스트 파일 네이밍: `ComponentName.test.tsx` (같은 디렉토리)
  - 셀렉터 우선순위: getByRole > getByLabelText > getByText > getByTestId
  - 4가지 테스트 유형: 렌더링 / Props / 이벤트 / 조건부 렌더링
  - `render()`, `screen`, `fireEvent`, `waitFor` 사용법
  - 비동기 컴포넌트 테스트: `waitFor` + `findBy*` 패턴
  - 사용자 상호작용: `userEvent` 패턴 (fireEvent보다 권장)

### 3. `frontend-api-mock-test`
- **allowed-tools**: Read, Write, Edit, Bash, Glob, Grep
- **내용**:
  - MSW v2 `http.get/post/put/delete` 핸들러 패턴
  - `setupServer` / `beforeAll` / `afterEach` / `afterAll` 설정
  - 성공/실패/타임아웃 시나리오 모킹
  - Axios 인터셉터 (401 → refresh → 재요청) 테스트 패턴
  - 에러 핸들링 3단계 각각의 테스트 방법
  - `frontend-axios` 스킬의 API 패턴과 연동

### 4. `frontend-e2e-test`
- **allowed-tools**: Read, Write, Edit, Bash, Glob, Grep
- **내용**:
  - 테스트 파일 위치: `e2e/` 디렉토리
  - Page Object Model 패턴
  - 시맨틱 셀렉터: `getByRole`, `getByLabel` 우선
  - 네트워크 대기: `waitForResponse`, `waitForURL`
  - 인증 상태 관리: `storageState` 패턴
  - 실패 시 자동 수집: 스크린샷 + trace
  - Flaky 테스트 방지 패턴

### 5. `frontend-visual-regression`
- **allowed-tools**: Read, Write, Edit, Bash, Glob, Grep
- **내용**:
  - `toHaveScreenshot()` 기본 사용법
  - 기준 스크린샷(baseline) 생성/업데이트: `--update-snapshots`
  - 반응형 뷰포트별 테스트 (375px, 768px, 1440px)
  - 동적 콘텐츠 마스킹: `mask` 옵션
  - `maxDiffPixelRatio` 임계값: 0.01 (1%)
  - 애니메이션 비활성화: `animations: 'disabled'`

### 6. `frontend-tdd-workflow`
- **allowed-tools**: Read, Write, Edit, Bash, Glob, Grep
- **내용**:
  - TDD 3단계: RED → GREEN → REFACTOR
  - 시작 전 인터페이스/타입 먼저 정의
  - 테스트 케이스 목록 사전 작성 후 하나씩 구현
  - 한 번에 하나의 테스트만 추가하는 규칙
  - `vitest --watch` / `vitest --run` 사용
  - 커버리지 80% 이상 확인 후 완료
  - 다른 5개 스킬과의 연계 방법

### 7. `frontend-test` 서브에이전트
- **model**: opus
- **skills**: 위 6개 전부
- **역할**: pm의 스펙을 받아서 테스트 코드를 작성하고 실행
- **테스트 작성 순서**: TDD workflow → unit → component → api-mock → (e2e, visual은 선택)

## 작업 순서

1. 스킬 디렉토리 6개 생성 + SKILL.md 작성 (병렬)
2. 서브에이전트 `frontend-test.md` 작성
3. 검증: 스킬 목록에 6개가 표시되는지 확인

## 검증

- `ls ~/.claude/skills/frontend-*-test*/SKILL.md` — 파일 존재 확인
- `ls ~/.claude/skills/frontend-tdd-workflow/SKILL.md` — 파일 존재 확인
- `cat ~/.claude/agents/frontend-test.md` — 에이전트 설정 확인
- Claude Code 재시작 후 스킬/에이전트 인식 여부 확인
