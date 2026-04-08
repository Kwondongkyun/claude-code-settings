## Claude Code 설정 점검 리포트

**현재 버전: 2.1.81** (최신)

---

### 점검 결과

| 상태 | 항목 | 설명 | 파일 |
|------|------|------|------|
| ⚠️ | blocklist 충돌 | `code-review@claude-plugins-official`이 `enabledPlugins`에서 `true`이면서 `blocklist.json`에도 등재됨. 런타임에 충돌 가능 | `settings.json`, `blocklist.json` |
| 🔧 | MCP 버전 고정 | playwright MCP가 `@0.0.68` 고정 — 현재 최신은 더 높을 수 있음. 주기적 버전 확인 권장 | `settings.json` |
| 🔧 | superpowers commit SHA 불일치 | superpowers만 다른 gitCommitSha (`e4a2375c...`), 나머지 6개는 동일 (`55b58ec6...`). 부분 업데이트 상태 | `installed_plugins.json` |
| 🔧 | skill-creator commit SHA 불일치 | skill-creator의 gitCommitSha (`61c0597779bd...`)가 다른 공식 플러그인들과 다름. 최근(3/22) 별도 설치 | `installed_plugins.json` |
| 🔧 | planning-with-files 오래된 설치 | `planning-with-files`가 2026-02-25 설치 후 미갱신 상태 (약 26일 경과). disabled 상태이므로 삭제 또는 업데이트 검토 | `installed_plugins.json` |
| 🔧 | 에이전트 model 필드 | `eval-all`, `frontend-test`, `pm`이 `model: opus` 사용 중. 2.1.81에서 Bedrock/Vertex 기본 Opus가 4.6으로 변경됨 — model ID 명시(`claude-opus-4-6`)가 더 명확 | `agents/*.md` |
| 💡 | --bare 플래그 | 2.1.81에서 추가된 `--bare` 플래그로 스크립트 호출 시 hooks/LSP/plugin 생략 가능. CI/자동화에 활용 가능 | — |
| 💡 | --channels 권한 릴레이 | 도구 승인 프롬프트를 모바일로 전달하는 `--channels` 기능 추가. 원격 작업 시 활용 가능 | — |
| 💡 | OAuth 토큰 동시 세션 수정 | 여러 세션 동시 사용 시 반복 재인증 문제 해결됨. 다중 세션 사용자에게 직접 혜택 | — |
| ✅ | 스킬 36개, 에이전트 5개, MCP 1개, 플러그인 8개 정상 | 현재 버전과 호환. hooks(5개) 정상 동작. CLAUDE.md 프로세스 구조 유효 | — |

### 적용 제안

- [ ] **blocklist 충돌 해소**: `code-review@claude-plugins-official`를 blocklist에서 제거하거나, `settings.json`의 `enabledPlugins`에서 `false`로 변경
  - blocklist: `~/.claude/plugins/blocklist.json` — `code-review@claude-plugins-official` 항목 제거
  - 또는 settings: `~/.claude/settings.json` — `"code-review@claude-plugins-official": false`로 변경
- [ ] **playwright MCP 버전 확인**: `npm view @playwright/mcp version`으로 최신 버전 확인 후 `settings.json`의 args 업데이트 검토
- [ ] **planning-with-files 정리**: 사용하지 않는 경우(`false`) 플러그인 제거 검토. 사용할 경우 `true`로 변경 후 업데이트
- [ ] **에이전트 model 명시화 (선택)**: `model: opus` → `model: claude-opus-4-6` 등으로 명시하면 모델 선택이 더 명확해짐 (현재 직접 API 사용 시에는 영향 없음)

*적용 여부는 사용자가 직접 판단합니다.*

---

Sources:
- [Claude Code Changelog](https://code.claude.com/docs/en/changelog)
- [GitHub Releases](https://github.com/anthropics/claude-code/releases)
- [Claude Code npm versions](https://www.npmjs.com/package/@anthropic-ai/claude-code?activeTab=versions)
