---
name: my-update-check
description: >
  Claude Code 업데이트를 확인하고, 변경사항이 내 설정(스킬/플러그인/MCP/hooks)에 미치는 영향을 분석하여 적용 제안을 하는 스킬.
  "업데이트 확인", "update check", "버전 확인", "새 버전 나왔어?", "뭐 바뀌었어?",
  "최신 버전이야?", "설정 점검", "내 설정 괜찮아?" 요청에 사용.
  Claude Code 버전, 릴리즈 노트, changelog, 업데이트 내역을 물어볼 때도 이 스킬을 사용할 것.
effort: medium
allowed-tools: Read, Glob, Grep, WebSearch, Bash(claude --version), Bash(npm view @anthropic-ai/claude-code *), Bash(curl -s https://api.github.com/*), Bash(curl -s https://raw.githubusercontent.com/*)
---

# My Update Check

Claude Code 공식 업데이트를 확인하고, 변경사항이 내 설정(스킬/에이전트/CLAUDE.md/MCP/플러그인)에
미치는 영향을 분석하여 적용 제안까지 하는 스킬.

> 확인 범위: Claude Code 공식 업데이트 + MCP/플러그인 설정 분석.
> 분석 대상: ~/.claude/skills/, ~/.claude/agents/, ~/.claude/CLAUDE.md, ~/.claude/settings.json, ~/.claude/plugins/

## Step 1: 데이터 수집 (전부 병렬)

아래 5개를 **동시에** 실행한다:

```bash
claude --version
```

```bash
npm view @anthropic-ai/claude-code version
```

```bash
curl -s "https://api.github.com/repos/anthropics/claude-code/releases?per_page=20"
```

```
Glob("~/.claude/skills/*/SKILL.md") + Grep(frontmatter) — 스킬 목록
Read("~/.claude/settings.json") — mcpServers, enabledPlugins 추출
Read("~/.claude/CLAUDE.md"), Read("~/.claude/agents/*.md"),
Read("~/.claude/plugins/installed_plugins.json"), Read("~/.claude/plugins/blocklist.json")
```

> 설정 파일 스캔은 GitHub Releases/WebSearch와 완전히 독립적이므로 지금 같이 시작한다.
> GitHub Releases 결과는 Step 1-A 또는 Step 2에서 재사용한다. 추가 API 호출 불필요.

버전 비교 결과에 따라:
- **동일**: Step 1-A(설정 점검)로 진행한다.
- **다름**: 현재 버전(`installed`)과 최신 버전(`latest`)을 기록하고 Step 2로 진행한다.

## Step 1-A: 설정 점검 (버전 동일 시)

최신 버전을 사용 중이므로, **내 설정이 현재 버전의 기능을 잘 활용하고 있는지** 점검한다.

`Glob("~/.claude/skills/my-update-check/references/settings-audit.md")`로 경로를 확인한 뒤 `Read` 도구로 읽고, 거기 적힌 가이드를 따른다.

> Step 1에서 가져온 GitHub Releases 결과를 재사용한다. 추가 API 호출 불필요.

Step 1-A 완료 후 **즉시 종료**한다. Step 2~4는 실행하지 않는다.

## Step 2: 변경사항 수집

### Step 2 시작 즉시: WebSearch 2개를 병렬로 선제 실행한다

CHANGELOG에는 잡히지 않는 플랫폼 레벨 변경을 수집하기 위해 아래 2개를 **즉시 병렬로** 실행한다:

```
WebSearch("Claude Code update {current_year}-{current_month} new features")
WebSearch("Claude Code skills agent update {current_year}")
```

GitHub Releases 처리와 WebSearch는 독립적이므로 동시에 진행한다.

### 주 소스: GitHub Releases (Step 1 결과 재사용)

Step 1에서 이미 가져온 GitHub Releases JSON 응답을 재사용한다 (추가 API 호출 불필요).

JSON에서:
1. 각 릴리즈의 `tag_name`, `published_at`, `body`를 추출한다.
2. `tag_name`에서 `v` 접두사를 제거하여 버전 번호를 파싱한다 (예: `v2.1.74` → `2.1.74`).
3. **현재 설치 버전 초과 ~ 최신 버전 이하** 범위의 릴리즈만 필터링한다.
4. 필터링된 릴리즈 노트(`body`)를 최신순으로 합친다.

### Fallback: CHANGELOG.md (Step 1에서 GitHub API가 실패한 경우에만)

```bash
curl -s "https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md"
```

가져온 CHANGELOG에서 현재 버전 헤딩(`## {installed}`) 이전까지의 내용만 추출한다.

### WebSearch 결과 처리

검색 결과에서 GitHub Releases에 없는 항목만 추출한다:
- Anthropic 공식 블로그 발표 (anthropic.com/news, anthropic.com/engineering)
- Claude API 변경사항 (/v1/skills 등 새 엔드포인트)
- 공식 문서 구조 변경 (Skills/Commands 통합 등)
- 내장 스킬 추가 (/simplify, /batch 등)
- Agent Skills 오픈 스탠다드 등 생태계 변화

**중복 제거**: GitHub Releases에서 이미 수집한 항목과 겹치는 내용은 제외한다.

### 변경사항 분류

수집된 내용(GitHub Releases + WebSearch)을 아래 카테고리로 분류한다:
- **신규 기능** (Added/New)
- **수정** (Fixed)
- **변경** (Changed/Improved)
- **제거/폐기** (Removed/Deprecated)
- **플랫폼/생태계** (WebSearch에서만 잡히는 항목)

## Step 3: 내 설정 영향 분석

### 분석 대상

Step 1에서 수집한 결과를 사용한다. 추가 파일 읽기 불필요.

| 대상 | 추출 내용 |
|------|----------|
| 스킬 frontmatter | name, description, allowed-tools |
| 에이전트 | model 필드, 전체 내용 |
| CLAUDE.md | 프로세스 규칙, 워크플로우 |
| settings.json | mcpServers(command/args/transport), enabledPlugins |
| installed_plugins.json | version, installedAt, gitCommitSha |
| blocklist.json | enabledPlugins와 교차 대조용 |

### 영향 판단 기준

Step 2에서 수집한 변경사항 각각에 대해, 분석 대상 파일들과 대조하여 3단계로 분류한다:

| 수준 | 기준 | 예시 |
|------|------|------|
| **직접 영향** | 내가 쓰는 기능이 변경/제거됨 | agents의 `model:` 필드 동작 변경, skill hooks 버그 수정 |
| **간접 영향** | 새 기능이 내 설정을 개선할 수 있음 | 새로운 frontmatter 필드 추가, 새 slash command |
| **무관** | 내 설정과 관계없음 | 타 OS 버그 수정, 안 쓰는 기능 변경 |

**판단 시 고려사항**:
- 에이전트 파일의 `model:` 필드 값과 모델 관련 변경사항 매칭
- 스킬의 `triggers:` 필드와 slash command 관련 변경사항 매칭
- CLAUDE.md의 프로세스/규칙과 워크플로우 관련 변경사항 매칭
- hooks, permissions 관련 변경사항과 `settings.json`의 permissions 섹션 매칭

#### MCP/플러그인 영향 매칭

릴리즈 노트의 각 변경사항에서 아래 키워드를 감지하고, 내 설정과 대조한다:

| 키워드 그룹 | 매칭 대상 | 판단 |
|------------|----------|------|
| `MCP`, `mcpServers`, `OAuth`, `transport` | `settings.json`의 `mcpServers` 서버 목록 | 해당 서버의 transport/auth 방식과 구체적으로 매칭 |
| `plugin`, `marketplace`, `plugin hooks` | `enabledPlugins` + `installed_plugins.json` | 현재 활성화된 플러그인에 직접 영향 가능 |
| `blocklist` | `blocklist.json` | blocklist 로직 변경 시 현재 등재된 플러그인 영향 |
| `permissions`, `allow`, `deny` | `settings.json` + `settings.local.json`의 `mcp__*` 패턴 | MCP 도구 권한 관련 변경 시 직접 영향 |

**매칭 원칙**:
1. 키워드 감지 → 내 설정에서 실제 사용 여부 확인
2. 사용 중이면 **직접 영향**, 활용 가능하면 **간접 영향**, 둘 다 아니면 **무관**
3. MCP OAuth 변경의 경우 내 MCP 서버가 OAuth를 쓰는지 command/args로 판단 (로컬 실행이면 무관)

## Step 4: 리포트 출력

화면에 직접 출력한다. 파일로 저장하지 않는다. 마크다운 테이블 중심으로 구조화한다.

### 리포트 템플릿

```markdown
## Claude Code 업데이트 리포트

**{installed}** → **{latest}** ({count}개 릴리즈 | {date_range})

---

### 내 설정에 직접 영향

| 변경 | 영향받는 파일 | 버전 |
|------|------------|------|
| {변경 내용} | {파일 경로} | {version} |
| ... | ... | ... |

### 활용할 수 있는 새 기능

| 기능 | 설명 | 버전 |
|------|------|------|
| {기능명} | {한줄 설명} | {version} |
| ... | ... | ... |

### 플랫폼/생태계 변경

| 변경 | 설명 |
|------|------|
| {항목} | {한줄 설명} |
| ... | ... |

### 적용 제안

- [ ] `npm update -g @anthropic-ai/claude-code`
- [ ] {구체적 제안 + 파일 경로}
- [ ] ...

*적용 여부는 사용자가 직접 판단합니다.*

---

Sources:
- [GitHub Releases](https://github.com/anthropics/claude-code/releases)
- {WebSearch에서 발견한 주요 소스 URL}
```

### 리포트 원칙
- **영향 순서로 출력**: 직접 영향 → 새 기능 → 플랫폼 변경 → 적용 제안. 가장 중요한 것이 먼저.
- **테이블로 구조화**: 변경사항은 반드시 테이블로. 산문체 나열 금지.
- **적용 제안은 체크리스트**: `- [ ]` 형식으로 액션 아이템화.
- **자동 실행 금지**: 적용 제안은 구체적 명령어와 파일 경로를 포함하되, 사용자 승인 없이 실행하지 않는다.
- **무관한 항목 생략**: 영향 없는 변경은 하단에 "그 외 {N}건은 내 설정과 무관" 한 줄로 처리.
- **간결하게**: 각 테이블은 최대 10행. 초과 시 상위 10개만 표시하고 나머지는 건수만 언급.

## Error Handling

| 시나리오 | 감지 방법 | 대응 |
|---------|----------|------|
| 네트워크 실패 | curl exit code != 0 또는 빈 응답 | "GitHub API에 연결할 수 없습니다" 출력 후 종료 |
| GitHub API rate limit | 403 응답 | CHANGELOG.md raw URL로 Fallback |
| npm 명령어 실패 | npm view 에러 | GitHub Releases의 최신 `tag_name`을 최신 버전으로 사용 |
| claude --version 실패 | 명령어 not found | "Claude Code가 PATH에 없습니다" 출력 후 종료 |

CLAUDE.md 원칙에 따라 같은 명령을 3번 이상 재시도하지 않는다. 실패 시 즉시 Fallback하거나 에러를 보고한다.

## Limitations

- 인증 없는 GitHub API는 시간당 60회 요청 제한
- 비공개 릴리즈(pre-release)는 포함하지 않음
- 설정 영향 분석은 키워드 기반 추론이므로 100% 정확하지 않을 수 있음
- MCP/플러그인 분석은 설정 파일 기반이며, 런타임 연결 상태는 확인하지 않음
- 플러그인 최신 버전 확인은 semver 표기 플러그인만 가능 (commit SHA 기반은 비교 불가)
- `settings.local.json`의 MCP 권한은 글로벌만 점검 (프로젝트별 차이 가능)
- WebSearch 결과는 검색 시점의 인덱싱 상태에 따라 최신 블로그/문서가 누락될 수 있음
