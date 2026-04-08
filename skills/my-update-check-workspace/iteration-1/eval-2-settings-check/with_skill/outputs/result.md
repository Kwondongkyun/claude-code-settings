## Claude Code 설정 점검 리포트

**현재 버전: 2.1.81** (최신)

---

### 점검 결과

| 상태 | 항목 | 설명 | 파일 |
|------|------|------|------|
| ⚠️ | blocklist 충돌 | `code-review@claude-plugins-official`이 enabledPlugins에서 `true`이면서 blocklist에 등재됨. 차단 의도와 활성화가 충돌 | `settings.json`, `blocklist.json` |
| ⚠️ | enabled vs installed 불일치 | `planning-with-files`가 enabledPlugins에서 `false`이지만 installed_plugins.json에 설치됨. 사용하지 않을 거면 제거 권장 | `settings.json`, `installed_plugins.json` |
| 🔧 | commit SHA 불일치 | `superpowers`(e4a2375c)와 `skill-creator`(61c05977)가 나머지 6개 공식 플러그인(55b58ec6)과 다른 SHA. 부분 업데이트 상태 | `installed_plugins.json` |
| 🔧 | planning-with-files 장기 미업데이트 | 설치일(2026-02-25) 이후 lastUpdated 없음(26일 경과). 다른 플러그인은 2026-03-21에 업데이트됨 | `installed_plugins.json` |
| 🔧 | 에이전트 model 필드 약어 사용 | `model: opus`, `model: sonnet` 약어 사용 중. full model ID(`claude-opus-4-6`, `claude-sonnet-4-5` 등) 명시 시 버전 고정 가능 | `agents/*.md` |
| 💡 | --bare 플래그 미활용 | 2.1.81에서 추가된 `--bare` 플래그(스크립트 호출 시 hooks/LSP/플러그인 스킵)를 CI/스크립트에 활용 가능 | — |
| 💡 | --channels 권한 릴레이 미활용 | 2.1.81에서 추가된 `--channels` 옵션으로 도구 승인 프롬프트를 모바일로 전달 가능 | — |
| 💡 | 스킬 allowed-tools 미지정 | 42개 스킬 중 상당수(day1~day6, my-content-digest, my-context-sync, my-fetch-*, my-session-wrap)에 `allowed-tools` frontmatter가 없음. 명시적 지정 시 보안/성능 개선 | `skills/*/SKILL.md` |
| ✅ | 스킬 42개, 에이전트 5개, MCP 1개, 플러그인 8개 정상 | 현재 버전과 호환. hooks(SessionStart, PreCompact, PostCompact, UserPromptSubmit, StopFailure) 5개 정상 구성 | — |

### 적용 제안

- [ ] **blocklist 충돌 해소**: `blocklist.json`에서 `code-review@claude-plugins-official` 항목을 제거하거나, `settings.json`의 `enabledPlugins`에서 해당 플러그인을 `false`로 변경
- [ ] **planning-with-files 정리**: 사용하지 않는다면 `enabledPlugins`에서 키 자체를 삭제하고, `~/.claude/plugins/cache/planning-with-files/` 디렉토리도 정리
- [ ] **플러그인 동기화**: `/settings` 또는 플러그인 관리에서 전체 업데이트 실행하여 commit SHA 통일
- [ ] **에이전트 model 필드 구체화**: `model: opus` → `model: claude-opus-4-6`, `model: sonnet` → `model: claude-sonnet-4-5`로 변경 검토 (버전 고정이 필요한 경우)
- [ ] **allowed-tools 미지정 스킬 보강**: 교육용(day1~day6) 스킬은 제외하더라도, `my-content-digest`, `my-context-sync`, `my-fetch-tweet`, `my-fetch-youtube`, `my-session-wrap` 스킬에 `allowed-tools` 추가 검토

*적용 여부는 사용자가 직접 판단합니다.*

---

Sources:
- [Claude Code Changelog](https://code.claude.com/docs/en/changelog)
- [GitHub Releases](https://github.com/anthropics/claude-code/releases)
- [npm @anthropic-ai/claude-code](https://www.npmjs.com/package/@anthropic-ai/claude-code)
