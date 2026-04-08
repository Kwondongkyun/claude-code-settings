# 트랜스크립트: Claude Code 버전 및 설정 점검

> 실행일: 2026-03-23

---

## Step 1: 버전 확인

### 현재 설치 버전 확인
```bash
$ claude --version
2.1.81 (Claude Code)
```

### npm 레지스트리 최신 버전 확인
```bash
$ npm show @anthropic-ai/claude-code version
2.1.81
```

**판단:** 현재 설치 버전(2.1.81)과 npm 최신 버전(2.1.81)이 동일. 최신 버전 사용 중.

---

## Step 2: 글로벌 설정 파일 확인

### settings.json 읽기
```bash
$ cat ~/.claude/settings.json
```

확인 항목:
- env: 9개 환경 변수 (텔레메트리, OTEL, 팀 에이전트)
- permissions: allow 4개, deny 15개, ask 12개
- hooks: 5개 (SessionStart, PreCompact, PostCompact, UserPromptSubmit, StopFailure)
- statusLine: statusline.sh 스크립트 연결
- enabledPlugins: 8개 (7개 활성화, 1개 비활성화)
- mcpServers: playwright 1개
- language: Korean
- teammateMode: auto

---

## Step 3: 훅 스크립트 존재 여부 확인

### 스크립트 디렉토리
```bash
$ ls ~/.claude/scripts/
context-bar.sh
init-context-files.sh
post-compact-reminder.sh
pre-compact-marker.sh
```

### notify.sh 확인
```bash
$ cat ~/.claude/notify.sh
cat: /Users/kwondong-kyun/.claude/notify.sh: No such file or directory
```

**문제 발견:** StopFailure 훅에서 참조하는 `~/.claude/notify.sh`가 존재하지 않음.

---

## Step 4: 상태라인 스크립트 확인

```bash
$ cat ~/.claude/statusline.sh
```

정상 동작하는 스크립트 확인됨. 모델, 디렉토리, 브랜치, 컨텍스트 사용률, 비용, 시간, 레이트 리밋 표시.

---

## Step 5: 템플릿 확인

```bash
$ ls ~/.claude/templates/
findings.md  memory.md  plan.md  progress.md  research.md
```

5개 템플릿 정상 존재.

---

## Step 6: 스킬 목록 확인

```bash
$ ls ~/.claude/skills/
```

40개 이상 스킬 디렉토리 확인됨.

---

## Step 7: CLAUDE.md 확인

```bash
$ cat ~/.claude/CLAUDE.md
```

글로벌 지시사항 정상 설정: 한국어 응답, Planning 규칙, Communication 규칙, 프로젝트 생성 프로세스(Phase 0-8), 컨텍스트 관리, 기본값.

---

## Step 8: 환경 정보

```bash
$ node -e "console.log(process.arch, process.platform)"
arm64 darwin
```

---

## 최종 결론

- **버전:** 최신 (2.1.81)
- **설정:** 전반적으로 양호
- **발견된 문제:** `~/.claude/notify.sh` 파일 누락 (StopFailure 훅 미작동)
