# Claude Code 버전 및 설정 점검 결과

> 점검일: 2026-03-23

---

## 1. 버전 확인

| 항목 | 값 |
|------|-----|
| 현재 설치 버전 | **2.1.81** |
| npm 레지스트리 최신 버전 | **2.1.81** |
| 상태 | **최신 버전 사용 중** |

---

## 2. 설정 점검 (`~/.claude/settings.json`)

### 2-1. 환경 변수 (env)

| 변수 | 값 | 상태 |
|------|-----|------|
| `CLAUDE_CODE_ENABLE_TELEMETRY` | `1` | 정상 - 텔레메트리 활성화 |
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | `1` | 정상 - 팀 에이전트 기능 활성화 |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `http://43.201.162.58:4317` | 정상 - OTLP 수집 엔드포인트 설정됨 |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | `grpc` | 정상 |
| `OTEL_METRIC_EXPORT_INTERVAL` | `60000` | 정상 - 60초 간격 |
| `OTEL_METRICS_EXPORTER` | `otlp` | 정상 |
| `OTEL_METRICS_INCLUDE_SESSION_ID` | `false` | 정상 - 프라이버시 고려 |
| `OTEL_RESOURCE_ATTRIBUTES` | `plan=TeamPremium,team=DEV` | 정상 |
| `OTEL_SERVICE_NAME` | `claude-code-eren.kwon` | 정상 |

### 2-2. 권한 설정 (permissions)

**허용 (allow):**
- `Bash(*)` - 모든 Bash 명령 허용
- `WebSearch` - 웹 검색 허용
- `mcp__playwright` - Playwright MCP 허용
- `mcp__pencil` - Pencil MCP 허용

**거부 (deny):** 위험한 시스템 명령 적절히 차단됨
- `rm -rf`, `killall`, `sudo`, `git push --force`, `npm publish` 등 파괴적 명령 차단
- `.env`, `secrets/**`, `~/.ssh/**` 민감 파일 읽기 차단

**확인 필요 (ask):** 중간 위험도 명령에 대한 확인 요청 설정
- `rm`, `curl`, `wget`, `git push`, `git reset --hard` 등

**평가:** 권한 설정이 3단계(allow/deny/ask)로 잘 구성되어 있음. 보안과 편의성 균형이 적절함.

### 2-3. 훅 (hooks)

| 훅 | 스크립트 | 상태 |
|----|---------|------|
| `SessionStart` | `init-context-files.sh` | 정상 |
| `PreCompact` | `pre-compact-marker.sh` | 정상 |
| `PostCompact` | `post-compact-reminder.sh` | 정상 |
| `UserPromptSubmit` | `post-compact-reminder.sh` | 정상 |
| `StopFailure` | `notify.sh` | **문제 발견** - 파일 없음 |

**문제:** `StopFailure` 훅에서 참조하는 `~/.claude/notify.sh` 파일이 존재하지 않음. API 에러 발생 시 알림이 작동하지 않음.

### 2-4. 상태 라인 (statusLine)

- `~/.claude/statusline.sh` 스크립트 정상 존재
- 모델명, 디렉토리, Git 브랜치, 컨텍스트 사용률, 비용, 소요 시간, 5시간/7일 레이트 리밋 표시
- 컨텍스트 사용률에 따른 색상 변화 (초록/노랑/빨강) 적용됨

### 2-5. 플러그인 (enabledPlugins)

| 플러그인 | 상태 |
|----------|------|
| code-review | 활성화 |
| context7 | 활성화 |
| github | 활성화 |
| planning-with-files | **비활성화** |
| ralph-loop | 활성화 |
| security-guidance | 활성화 |
| superpowers | 활성화 |
| skill-creator | 활성화 |

### 2-6. MCP 서버

| 서버 | 명령 | 상태 |
|------|------|------|
| playwright | `npx @playwright/mcp@0.0.68` | 정상 |

### 2-7. 기타 설정

| 항목 | 값 | 상태 |
|------|-----|------|
| `language` | `Korean` | 정상 |
| `teammateMode` | `auto` | 정상 |

---

## 3. CLAUDE.md 점검

- `~/.claude/CLAUDE.md` (글로벌): 정상 - 한국어 응답, Planning, Communication, 프로젝트 프로세스, 컨텍스트 관리 규칙 설정됨
- 프로젝트별 `CLAUDE.md`: 정상 - 연구 문서 작성 규칙, Notion 동기화 규칙 포함

---

## 4. 기타 리소스

- **템플릿 (5개):** findings.md, memory.md, plan.md, progress.md, research.md
- **훅 스크립트 (4개):** context-bar.sh, init-context-files.sh, post-compact-reminder.sh, pre-compact-marker.sh
- **스킬:** 40개 이상 등록됨
- **환경:** macOS (Darwin), ARM64 (Apple Silicon)

---

## 5. 발견된 문제 및 권장 조치

| # | 심각도 | 문제 | 권장 조치 |
|---|--------|------|-----------|
| 1 | **중간** | `~/.claude/notify.sh` 파일 누락 | StopFailure 훅이 작동하지 않음. 알림 스크립트를 생성하거나 훅에서 해당 항목을 제거할 것 |
| 2 | **낮음** | `planning-with-files` 플러그인 비활성화 | 의도적 비활성화인지 확인 필요 |

---

## 요약

Claude Code **2.1.81** 버전은 현재 npm 레지스트리 기준 **최신 버전**임. 전반적인 설정은 잘 구성되어 있으며, 권한 관리(3단계), 훅, 상태라인, 컨텍스트 관리 등이 체계적으로 설정됨. 유일한 실질적 문제는 `notify.sh` 파일 누락으로, StopFailure 시 알림이 동작하지 않는 점임.
