## Claude Code 설정 점검 리포트

**현재 버전: 2.1.81** (최신)

---

### 점검 결과

| 상태 | 항목 | 설명 | 파일 |
|------|------|------|------|
| ⚠️ | blocklist 충돌 | `code-review` 플러그인이 `enabledPlugins`에서 `true`이면서 `blocklist.json`에도 등재됨. blocklist 사유: "just-a-test" | `settings.json`, `blocklist.json` |
| ⚠️ | enabled vs installed 불일치 | `planning-with-files@planning-with-files`가 `enabledPlugins`에서 `false`지만 `installed_plugins.json`에 설치됨 (비활성 상태로 잔존). 의도적 비활성이면 무관 | `settings.json`, `installed_plugins.json` |
| 🔧 | commit SHA 불일치 | `superpowers`만 다른 SHA (`e4a237...`), 나머지 official 6개는 `55b58e...`, `skill-creator`는 `61c059...`. 부분 업데이트 상태 | `installed_plugins.json` |
| 🔧 | planning-with-files 장기 미업데이트 | `planning-with-files` 설치일 2026-02-25, lastUpdated도 동일. 약 26일 경과, 업데이트 확인 권장 | `installed_plugins.json` |
| 🔧 | MCP playwright 버전 고정 | playwright MCP가 `@0.0.68`로 고정되어 있어 안정적이나, 최신 버전 확인 권장 | `settings.json` |
| 🔧 | `/output-style` deprecated | 2.1.81에서 `/output-style` 커맨드가 폐기되고 `/config`로 통합됨. `settings.local.json`에 `"outputStyle": "Explanatory"` 설정 존재. 파일 설정은 정상 동작하나, 슬래시 커맨드로 변경하던 습관이 있다면 `/config` 사용 필요 | `settings.local.json` |
| 💡 | `--bare` 플래그 미활용 | 2.1.81에 추가된 `--bare` 플래그로 스크립트용 `-p` 호출 시 hooks/LSP/플러그인 동기화/스킬 디렉토리 워크를 건너뛸 수 있음. CI/자동화 스크립트에서 성능 향상 가능 | — |
| 💡 | `--channels` 권한 릴레이 미활용 | 2.1.81의 새 기능. 채널 서버가 permission capability를 선언하면 도구 승인 프롬프트를 모바일로 전달 가능. 원격 작업 시 유용 | — |
| 💡 | Opus 4.6 기본 모델 변경 | Bedrock/Vertex/Foundry에서 기본 Opus가 4.1 → 4.6으로 변경됨. 에이전트 파일에서 `model: opus`로 지정한 경우 (eval-all, frontend-test, pm) 자동으로 최신 모델 적용 | `agents/*.md` |
| 💡 | MCP Tool Search (lazy loading) | MCP 도구를 지연 로딩하여 컨텍스트 사용량 최대 95% 절감 가능. 현재 playwright 1개만 사용 중이라 영향 제한적이나, MCP 추가 시 유용 | — |
| ✅ | 스킬 42개, 에이전트 5개, MCP 1개, 플러그인 8개 정상 | 현재 버전과 호환. hooks 구조(SessionStart, PreCompact, PostCompact, UserPromptSubmit, StopFailure) 정상. statusLine 정상. permissions deny/ask 패턴 정상 | — |

### 적용 제안

- [ ] **blocklist 충돌 해소**: `code-review@claude-plugins-official`이 blocklist에 테스트용으로 등재됨 (`"reason": "just-a-test"`). 테스트 완료 시 blocklist에서 제거하거나, 정말 차단할 의도면 `enabledPlugins`에서 `false`로 변경 → `~/.claude/plugins/blocklist.json` 및 `~/.claude/settings.json`
- [ ] **플러그인 SHA 통일**: `superpowers`와 `skill-creator`가 다른 SHA. `skill-creator`는 최근(3/22) 설치라 정상이지만, `superpowers`는 semver(5.0.5) 기반이라 별도 업데이트 사이클. 플러그인 업데이트 명령으로 최신화 확인
- [ ] **planning-with-files 정리**: 현재 비활성(`false`) 상태. 사용 계획이 없으면 `enabledPlugins`에서 제거하여 설정 정리. 사용할 거면 최신 버전 확인
- [ ] **`/output-style` → `/config` 전환**: 런타임에서 출력 스타일 변경 시 `/config` 사용. `settings.local.json`의 `outputStyle` 설정은 그대로 유지해도 무방
- [ ] **CI/자동화에 `--bare` 적용 검토**: 스크립트에서 `claude -p` 호출 시 `--bare` 추가로 불필요한 초기화 건너뛰기 가능

*적용 여부는 사용자가 직접 판단합니다.*

---

Sources:
- [GitHub Releases](https://github.com/anthropics/claude-code/releases)
- [Claude Code Changelog](https://code.claude.com/docs/en/changelog)
- [Releasebot - March 2026 Updates](https://releasebot.io/updates/anthropic/claude-code)
- [Claude Code Skills Docs](https://code.claude.com/docs/en/skills)
