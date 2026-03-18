# 조합 1: Agent Team(TeamCreate)으로 Todo 앱 개발

## Context

4가지 AI 개발 자동화 조합을 실제 테스트하는 프로젝트의 첫 번째 실험.
TeamCreate 기반 Agent Team으로 Todo 앱을 1회성 병렬 협업으로 개발한다.

이전 3회 시도에서 tmux 기반 에이전트 스폰 시 프롬프트가 전달되지 않는 문제 발생.
이번에는 환경 정리 후 재시도한다.

## 사전 정리 (환경 클린업)

1. **이전 세션 잔여물 정리**
   ```bash
   rm -rf ~/.claude/tasks/*    # 16개 UUID 폴더 정리
   rm -rf ~/.claude/teams/*    # 팀 설정 정리
   ```

2. **tmux 세션 확인**
   ```bash
   tmux list-panes -a          # 불필요한 pane 없는지 확인
   ```

## 실행 계획

### Step 1. Next.js 프로젝트 생성
- 경로: `/Users/kwondong-kyun/Desktop/test/ralph-loop/1-agent-team/todo-app`
- `npx create-next-app@latest todo-app --typescript --tailwind --eslint --app --src-dir`

### Step 2. TeamCreate
```
TeamCreate("todo-team-1", description="조합 1: Agent Team — Todo 앱")
```

### Step 3. TaskCreate + 의존성 설정
```
#1 기획서 작성 (pm)
#2 타입+훅 구현 (frontend-a) [blocked by #1]
#3 UI 컴포넌트 구현 (frontend-b) [blocked by #1]
#4 메인 페이지 구현 (frontend-c) [blocked by #2, #3]
#5 코드 리뷰 (reviewer) [blocked by #4]
#6 테스트 작성 (tester) [blocked by #4]
```

### Step 4. 순차 스폰

**Phase 1 — PM (1명)**
```
Task(subagent_type="pm", name="pm", team_name="todo-team-1",
     prompt="Task #1 수행. docs/specs/todo/에 prd.md, user-flow.md, error-scenario.md 작성")
```
→ 완료 대기

**Phase 2 — 개발자 병렬 (2명)**
```
Task(subagent_type="frontend", name="dev-hook", team_name="todo-team-1",
     prompt="Task #2 수행. src/features/todo/에 타입+훅 구현", run_in_background=true)
Task(subagent_type="frontend", name="dev-ui", team_name="todo-team-1",
     prompt="Task #3 수행. src/components/todo/에 UI 컴포넌트 구현", run_in_background=true)
```
→ 둘 다 완료 대기

**Phase 3 — 메인 페이지 (1명)**
```
Task(subagent_type="frontend", name="dev-page", team_name="todo-team-1",
     prompt="Task #4 수행. src/app/page.tsx에 메인 페이지 구현")
```
→ 완료 대기

**Phase 4 — 리뷰+테스트 병렬 (2명)**
```
Task(subagent_type="frontend-reviewer", name="reviewer", team_name="todo-team-1",
     prompt="Task #5 수행. 전체 코드 리뷰 → REVIEW.md", run_in_background=true)
Task(subagent_type="frontend-test", name="tester", team_name="todo-team-1",
     prompt="Task #6 수행. 테스트 코드 작성 및 실행", run_in_background=true)
```
→ 둘 다 완료 대기

### Step 5. 팀 종료
```
SendMessage(type="shutdown_request") → 각 에이전트
TeamDelete()
```

## 트러블슈팅 (tmux 문제 재발 시)

에이전트가 프롬프트를 받지 못하고 멈추면:

1. **tmux pane 출력 확인**: `tmux capture-pane -t %N -p`
2. **30초 대기 후에도 안 되면**: tmux pane kill 후 재스폰
3. **2회 연속 실패 시**: TeamCreate 포기하고 Task 직접 스폰으로 전환
   - team_name 파라미터 없이 Task 도구만 사용
   - SendMessage 불가하지만 안정적으로 동작

## 사용 에이전트

| 에이전트 | 파일 | 모델 | 역할 |
|---------|------|------|------|
| pm | ~/.claude/agents/pm.md | opus | 기획서 작성 |
| frontend ×3 | ~/.claude/agents/frontend.md | sonnet | 타입+훅, UI, 페이지 |
| frontend-reviewer | ~/.claude/agents/frontend-reviewer.md | sonnet | 코드 리뷰 |
| frontend-test | ~/.claude/agents/frontend-test.md | opus | 테스트 |

## 검증

1. `npm run build` — 빌드 성공 여부
2. `npm run dev` — 로컬에서 Todo 앱 정상 동작
3. 기획서 3개 파일 존재: `docs/specs/todo/{prd,user-flow,error-scenario}.md`
4. REVIEW.md 존재
5. 테스트 통과: `npx vitest --run`
6. report.md에 결과 기록
