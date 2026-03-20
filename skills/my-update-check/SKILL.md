---
name: my-update-check
description: Claude Code 업데이트를 확인하고 내 설정 영향을 분석하는 스킬. "업데이트 확인", "update check", "버전 확인" 요청에 사용.
allowed-tools: Read, Glob, Grep, WebSearch, Bash(claude --version), Bash(npm view *), Bash(curl *)
---

# My Update Check

Claude Code 공식 업데이트를 확인하고, 변경사항이 내 설정(스킬/에이전트/CLAUDE.md/MCP/플러그인)에
미치는 영향을 분석하여 적용 제안까지 하는 스킬.

> 확인 범위: Claude Code 공식 업데이트 + MCP/플러그인 설정 분석.
> 분석 대상: ~/.claude/skills/, ~/.claude/agents/, ~/.claude/CLAUDE.md, ~/.claude/settings.json, ~/.claude/plugins/

## 데이터 소스

| 소스 | 용도 | 명령어 |
|------|------|--------|
| npm 레지스트리 | 최신 버전 번호 | `npm view @anthropic-ai/claude-code version` |
| GitHub Releases API | 코드 레벨 변경사항 (JSON) | `curl -s "https://api.github.com/repos/anthropics/claude-code/releases?per_page=20"` |
| WebSearch | 블로그/문서/플랫폼 레벨 변경 | `WebSearch("Claude Code update {year}-{month}")` |
| CHANGELOG.md | Fallback (API 실패 시) | `curl -s "https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md"` |

## Step 1: 버전 비교

두 명령어를 **병렬로** 실행한다 (Bash 도구 2개 동시 호출):

```bash
claude --version
```

```bash
npm view @anthropic-ai/claude-code version
```

버전 비교 결과에 따라:
- **동일**: Step 1-A(설정 점검)로 진행한다.
- **다름**: 현재 버전(`installed`)과 최신 버전(`latest`)을 기록하고 Step 2로 진행한다.

## Step 1-A: 설정 점검 (버전 동일 시)

최신 버전을 사용 중이므로, **내 설정이 현재 버전의 기능을 잘 활용하고 있는지** 점검한다.

### 데이터 수집

아래를 **병렬로** 실행한다:

1. **현재 버전 릴리즈 노트** (GitHub API에서 현재 버전 1건만 추출)
```bash
curl -s "https://api.github.com/repos/anthropics/claude-code/releases?per_page=5"
```
JSON에서 `tag_name`이 현재 버전과 일치하는 릴리즈의 `body`만 추출한다.

2. **현재 기능 검색**
```
WebSearch("Claude Code {version} features capabilities {current_year}")
```

3. **내 설정 파일 스캔** (Step 3의 분석 대상과 동일)
- `~/.claude/skills/*/SKILL.md` — frontmatter 수집
- `~/.claude/agents/*.md` — 전체 읽기
- `~/.claude/CLAUDE.md` — 전체 읽기
- `~/.claude/settings.json` — **1번만 읽고** `mcpServers`와 `enabledPlugins` 동시 추출
- `~/.claude/plugins/installed_plugins.json` — 전체 읽기 (version, installedAt, gitCommitSha)
- `~/.claude/plugins/blocklist.json` — 전체 읽기 (enabledPlugins와 교차 대조)

### 점검 항목

수집한 데이터를 기반으로 아래 관점에서 점검한다:

| 관점 | 점검 내용 | 예시 |
|------|----------|------|
| **미활용 기능** | 현재 버전에서 지원하지만 내 설정에서 쓰지 않는 기능 | `${CLAUDE_SKILL_DIR}` 미사용, 새 frontmatter 필드 미적용 |
| **폐기 예정** | deprecated된 기능을 여전히 사용 중 | 제거된 slash command 참조, 구버전 설정 형식 |
| **최적화 가능** | 동작하지만 더 나은 방식이 있음 | `model: opus` → full model ID 명시 가능, 불필요한 allowed-tools |
| **정상 확인** | 현재 버전과 호환되며 잘 활용 중 | 스킬 구조 정상, 에이전트 설정 최신 |

#### MCP 점검 세부 항목

| 점검 | 방법 | 관점 |
|------|------|------|
| `@latest` 태그 사용 | args에 `@latest` 포함 시 버전 고정 권장 검토 | 🔧 최적화 가능 |
| 미사용 MCP 권한 | `permissions.allow`에 `mcp__*` 허용이 있지만 해당 서버가 `mcpServers`에 없음 | ⚠️ 폐기/비권장 |
| 새 공식 MCP 서버 | WebSearch로 현재 버전에서 추가된 공식 MCP 검색 | 💡 미활용 |
| MCP command 유효성 | command가 유효한 실행자인지 (`npx`, `node`, `python` 등) | ✅ 정상 |
| permissions 정합성 | `settings.json`과 `settings.local.json`의 `mcp__*` 패턴 비교 | 🔧 최적화 가능 |

#### 플러그인 점검 세부 항목

| 점검 | 방법 | 관점 |
|------|------|------|
| blocklist 충돌 | `enabledPlugins` 키와 `blocklist.json`의 `plugins[].plugin` 교차 대조 | ⚠️ 폐기/비권장 |
| 설치 후 경과 기간 | `installedAt` 기준 90일 이상 경과 시 업데이트 권장 | 🔧 최적화 가능 |
| commit SHA 불일치 | 같은 마켓플레이스 내 `gitCommitSha` 비교. 불일치 시 부분 업데이트 상태 | 🔧 최적화 가능 |
| enabled vs installed 불일치 | `enabledPlugins`에 있지만 `installed_plugins.json`에 없거나 그 반대 | ⚠️ 폐기/비권장 |

### 리포트 템플릿

```markdown
## Claude Code 설정 점검 리포트

**현재 버전: {version}** (최신)

---

### 점검 결과

| 상태 | 항목 | 설명 | 파일 |
|------|------|------|------|
| ⚠️ | blocklist 충돌 | `code-review` 플러그인이 enabled이면서 blocklist에 등재 | `settings.json`, `blocklist.json` |
| 🔧 | MCP 버전 고정 | playwright MCP가 `@latest` 사용 중 | `settings.json` |
| 🔧 | commit SHA 불일치 | superpowers만 다른 SHA, 부분 업데이트 상태 | `installed_plugins.json` |
| 💡 | {미활용 기능} | {설명} | {파일 경로} |
| ⚠️ | {폐기/비권장} | {설명} | {파일 경로} |
| 🔧 | {최적화 가능} | {설명} | {파일 경로} |
| ✅ | 스킬 {N}개, 에이전트 {N}개, MCP {N}개, 플러그인 {N}개 정상 | 현재 버전과 호환 | — |

### 적용 제안

- [ ] {구체적 제안 + 파일 경로}
- [ ] ...

*적용 여부는 사용자가 직접 판단합니다.*
```

### 리포트 원칙
- **상태 아이콘**: 💡 미활용, ⚠️ 폐기/비권장, 🔧 최적화 가능, ✅ 정상
- **테이블 1개로 집약**: 간결하게. 최대 15행.
- **정상 항목은 요약**: 개별 나열 대신 "스킬 {N}개 정상, 에이전트 {N}개 정상" 식으로 묶기
- **자동 실행 금지**: 적용 제안만 제시, 실행은 사용자 승인 후

Step 1-A 완료 후 **즉시 종료**한다. Step 2~4는 실행하지 않는다.

## Step 2: 변경사항 수집

### 주 소스: GitHub Releases API

```bash
curl -s "https://api.github.com/repos/anthropics/claude-code/releases?per_page=20"
```

JSON 응답에서:
1. 각 릴리즈의 `tag_name`, `published_at`, `body`를 추출한다.
2. `tag_name`에서 `v` 접두사를 제거하여 버전 번호를 파싱한다 (예: `v2.1.74` → `2.1.74`).
3. **현재 설치 버전 초과 ~ 최신 버전 이하** 범위의 릴리즈만 필터링한다.
4. 필터링된 릴리즈 노트(`body`)를 최신순으로 합친다.

### Fallback: CHANGELOG.md

GitHub API가 실패하거나 rate limit(403 응답)인 경우:

```bash
curl -s "https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md"
```

가져온 CHANGELOG에서 현재 버전 헤딩(`## {installed}`) 이전까지의 내용만 추출한다.

### 보조 소스: WebSearch (GitHub Releases와 병렬 실행)

CHANGELOG에는 잡히지 않는 플랫폼 레벨 변경(블로그 발표, API 변경, 문서 업데이트, 새 내장 스킬 등)을 수집한다.

아래 2개 검색을 **병렬로** 실행한다:

```
WebSearch("Claude Code update {current_year}-{current_month} new features")
WebSearch("Claude Code skills agent update {current_year}")
```

검색 결과에서 CHANGELOG에 없는 항목만 추출한다:
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

| 대상 | 경로 | 방식 |
|------|------|------|
| 스킬 | `~/.claude/skills/*/SKILL.md` | frontmatter(name, description)만 먼저 Grep으로 빠르게 수집. 관련 있는 스킬만 본문 상세 확인. |
| 에이전트 | `~/.claude/agents/*.md` | 전체 읽기 (소수) |
| CLAUDE.md | `~/.claude/CLAUDE.md` | 전체 읽기 |
| MCP 서버 + 플러그인 | `~/.claude/settings.json` | **1번만 읽고** `mcpServers`와 `enabledPlugins` 동시 추출 |
| 플러그인 메타데이터 | `~/.claude/plugins/installed_plugins.json` | 전체 읽기. version, installedAt, gitCommitSha 추출 |
| blocklist | `~/.claude/plugins/blocklist.json` | 전체 읽기. enabledPlugins와 교차 대조 |

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
| `plugin`, `marketplace`, `plugin hooks` | `enabledPlugins` + `installed_plugins.json` | 7개 플러그인 사용 중이므로 직접 영향 가능 |
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
