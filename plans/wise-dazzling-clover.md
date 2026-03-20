# my-update-check 스킬 구현 계획

## Context

Claude Code가 거의 매일 업데이트되는데(현재 v2.1.63, 최신 v2.1.74로 11버전 차이), 매번 공식 사이트나 GitHub를 직접 확인하기 번거롭다. `/update-check` 한 번이면 버전 확인부터 내 설정 영향 분석, 적용 제안까지 한번에 처리하는 스킬을 만든다.

## 생성할 파일

`~/.claude/skills/my-update-check/SKILL.md` (1개)

## 참조할 기존 패턴

| 파일 | 참조 포인트 |
|------|------------|
| `~/.claude/skills/my-context-sync/SKILL.md` | frontmatter 형식, 단계별 실행 흐름, 병렬 수집 패턴 |
| `~/.claude/skills/my-fetch-tweet/SKILL.md` | 외부 API 호출 + Fallback + Limitations 구조 |

## SKILL.md 구조

```
---
name: my-update-check
description: Claude Code 업데이트를 확인하고 내 설정 영향을 분석하는 스킬. "업데이트 확인", "update check", "버전 확인" 요청에 사용.
---

# My Update Check
(한줄 설명)

## 데이터 소스
## Step 1: 버전 비교
## Step 2: 변경사항 수집
## Step 3: 내 설정 영향 분석
## Step 4: 리포트 출력
## Error Handling
## Limitations
```

## 실행 흐름 상세

### Step 1: 버전 비교

두 명령어를 **병렬** 실행:
- `claude --version` → 현재 설치 버전
- `npm view @anthropic-ai/claude-code version` → npm 최신 버전

동일하면 "최신 상태" 출력 후 **즉시 종료**. 다르면 Step 2로.

### Step 2: 변경사항 수집

**주 소스**: GitHub Releases API
```bash
curl -s "https://api.github.com/repos/anthropics/claude-code/releases?per_page=20"
```
- JSON에서 `tag_name`, `published_at`, `body` 추출
- 현재 버전 초과 ~ 최신 버전 이하 범위만 필터링

**Fallback** (API 실패/rate limit 시): CHANGELOG.md raw 파일
```bash
curl -s "https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md"
```

### Step 3: 내 설정 영향 분석

**분석 대상** (확정):
- `~/.claude/skills/*/SKILL.md` (40개) — frontmatter만 먼저 읽고, 관련 있는 것만 상세 확인
- `~/.claude/agents/*.md` (5개)
- `~/.claude/CLAUDE.md` (1개)

**영향 판단 3단계**:

| 수준 | 기준 | 예시 |
|------|------|------|
| **직접 영향** | 내가 쓰는 기능이 변경/제거됨 | agents의 `model:` 필드 동작 변경 |
| **간접 영향** | 새 기능이 내 설정을 개선할 수 있음 | 새 설정 옵션 추가 |
| **무관** | 내 설정과 관계없음 | 타 OS 버그 수정 |

### Step 4: 리포트 출력

화면 출력만 (파일 저장 안 함). 적용 제안은 구체적 명령어 포함하되 **자동 실행 금지**.

```
══════════════════════════════════════════
  Claude Code 업데이트 리포트
══════════════════════════════════════════

  버전 정보
  ─────────
  설치: 2.1.63 → 최신: 2.1.74 (11개 릴리즈)

  주요 변경사항
  ─────────────
  [신규] ...
  [수정] ...
  [변경] ...

  내 설정 영향 분석
  ─────────────────
  [직접] agents/frontend.md → ...
  [간접] CLAUDE.md → ...
  [무관] 나머지 N개 스킬 — 영향 없음

  적용 제안
  ─────────
  1. 업데이트: npm update -g @anthropic-ai/claude-code
  2. (구체적 설정 변경 제안)
══════════════════════════════════════════
```

## Error Handling

| 시나리오 | 대응 |
|---------|------|
| 네트워크 실패 | 에러 메시지 출력 후 종료 |
| GitHub rate limit | CHANGELOG.md로 Fallback |
| npm 실패 | GitHub Releases의 최신 tag_name 사용 |
| claude 미설치 | 안내 메시지 후 종료 |

## 검증 방법

1. `/update-check` 호출하여 스킬이 정상 로드되는지 확인
2. 버전 비교 → 변경사항 수집 → 영향 분석 → 리포트 순서로 실행되는지 확인
3. 최신 버전인 경우 조기 종료 동작 확인
4. GitHub API 접근 불가 시 CHANGELOG.md Fallback 동작 확인
