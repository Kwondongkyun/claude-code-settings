# 설정 점검 가이드 (Step 1-A)

최신 버전을 사용 중일 때, 내 설정이 현재 버전의 기능을 잘 활용하고 있는지 점검하는 가이드.

## 데이터 수집

아래를 **병렬로** 실행:

1. **현재 버전 릴리즈 노트** — Step 1에서 가져온 GitHub Releases 결과를 재사용한다.
   JSON에서 `tag_name`이 현재 버전과 일치하는 릴리즈의 `body`만 추출. (추가 API 호출 불필요)

2. **현재 기능 검색**
```
WebSearch("Claude Code {version} features capabilities {current_year}")
```

3. **내 설정 파일 스캔**
- `~/.claude/skills/*/SKILL.md` — frontmatter 수집
- `~/.claude/agents/*.md` — 전체 읽기
- `~/.claude/CLAUDE.md` — 전체 읽기
- `~/.claude/settings.json` — **1번만 읽고** `mcpServers`와 `enabledPlugins` 동시 추출
- `~/.claude/plugins/installed_plugins.json` — 전체 읽기
- `~/.claude/plugins/blocklist.json` — 전체 읽기

## 점검 관점

| 관점 | 점검 내용 | 예시 |
|------|----------|------|
| **💡 미활용 기능** | 현재 버전에서 지원하지만 안 쓰는 기능 | `${CLAUDE_SKILL_DIR}` 미사용, 새 frontmatter 필드 미적용 |
| **⚠️ 폐기 예정** | deprecated된 기능을 여전히 사용 중 | 제거된 slash command, 구버전 설정 |
| **🔧 최적화 가능** | 동작하지만 더 나은 방식이 있음 | `model: opus` → full model ID, 불필요한 allowed-tools |
| **✅ 정상** | 현재 버전과 호환되며 잘 활용 중 | — |

## MCP 점검

| 점검 | 방법 | 관점 |
|------|------|------|
| `@latest` 태그 사용 | args에 `@latest` 포함 시 버전 고정 권장 | 🔧 |
| 미사용 MCP 권한 | `permissions.allow`에 `mcp__*` 있지만 서버가 없음 | ⚠️ |
| 새 공식 MCP | WebSearch로 현재 버전에서 추가된 공식 MCP 검색 | 💡 |
| command 유효성 | command가 유효한 실행자인지 | ✅ |
| permissions 정합성 | `settings.json`과 `settings.local.json`의 `mcp__*` 비교 | 🔧 |

## 플러그인 점검

| 점검 | 방법 | 관점 |
|------|------|------|
| blocklist 충돌 | `enabledPlugins` 키와 `blocklist.json` 교차 대조 | ⚠️ |
| 설치 후 경과 기간 | `installedAt` 기준 90일 이상 경과 시 업데이트 권장 | 🔧 |
| commit SHA 불일치 | 같은 마켓플레이스 내 SHA 비교. 불일치 시 부분 업데이트 | 🔧 |
| enabled vs installed 불일치 | enabledPlugins에 있지만 installed에 없거나 반대 | ⚠️ |

## 리포트 템플릿

```markdown
## Claude Code 설정 점검 리포트

**현재 버전: {version}** (최신)

---

### 점검 결과

| 상태 | 항목 | 설명 | 파일 |
|------|------|------|------|
| {아이콘} | {항목} | {설명} | {파일 경로} |

### 적용 제안

- [ ] {구체적 제안 + 파일 경로}

*적용 여부는 사용자가 직접 판단합니다.*
```

### 리포트 원칙
- **상태 아이콘**: 💡 미활용, ⚠️ 폐기/비권장, 🔧 최적화 가능, ✅ 정상
- **테이블 1개로 집약**: 간결하게. 최대 15행.
- **정상 항목은 요약**: "스킬 {N}개 정상" 식으로 묶기
- **자동 실행 금지**: 적용 제안만 제시, 실행은 사용자 승인 후

점검 완료 후 **즉시 종료**. Step 2~4는 실행하지 않음.
