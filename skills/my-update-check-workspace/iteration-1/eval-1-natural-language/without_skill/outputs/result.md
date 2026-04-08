# Claude Code 최신 버전 확인 결과

> 확인 일시: 2026-03-23

## 현재 상태

| 항목 | 값 |
|------|-----|
| 설치된 버전 | **2.1.81** |
| npm 최신 버전 | **2.1.81** |
| 최신 릴리스 날짜 | 2026-03-20 |
| 업데이트 필요 여부 | 최신 버전 사용 중 |

---

## v2.1.81 주요 변경사항 (2026-03-20)

### 새 기능
- **`--bare` 플래그 추가**: 스크립트용 `-p` 호출 시 hooks, LSP, 플러그인 동기화, 스킬 디렉토리 탐색을 건너뜀. `ANTHROPIC_API_KEY` 또는 `apiKeyHelper` 필요 (OAuth/키체인 인증 비활성화). 자동 메모리 완전 비활성화
- **`--channels` 권한 릴레이 추가**: permission capability를 선언한 채널 서버가 도구 승인 프롬프트를 휴대폰으로 전달 가능
- MCP read/search 도구 호출이 단일 "Queried {server}" 라인으로 축소 표시 (Ctrl+O로 확장)
- `!` bash 모드 발견성 개선 - 인터랙티브 명령 필요 시 Claude가 제안
- 플러그인 최신성 개선 - ref-tracked 플러그인이 매 로드시 re-clone하여 업스트림 변경 반영
- MCP OAuth가 Client ID Metadata Document (CIMD / SEP-991) 지원

### 버그 수정
- 여러 Claude Code 세션 동시 사용 시 OAuth 토큰 갱신으로 반복 재인증 필요했던 문제 수정
- 음성 모드에서 재시도 실패를 무시하고 "check your network" 오류 표시하던 문제 수정
- 음성 모드에서 서버가 WebSocket 연결을 끊으면 오디오가 복구되지 않던 문제 수정
- `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS`가 structured-outputs 베타 헤더를 억제하지 못해 프록시에서 400 에러 발생하던 문제 수정
- Node.js 18에서 크래시 수정
- 대시 포함 문자열의 Bash 명령에서 불필요한 권한 프롬프트 수정
- 워크트리에서 세션 재개 시 해당 워크트리로 전환되도록 수정
- [VSCode] Windows에서 Git Bash 사용 시 PATH 상속 문제 수정 (v2.1.78 회귀)

### 기타 변경
- Plan 모드에서 "clear context" 옵션이 기본 숨김으로 변경 (`"showClearContextOnPlanAccept": true`로 복원 가능)
- Windows(WSL 포함)에서 렌더링 문제로 줄 단위 응답 스트리밍 비활성화

---

## v2.1.80 주요 변경사항 (2026-03-19)

### 새 기능
- statusline 스크립트에 `rate_limits` 필드 추가 (5시간/7일 사용률 표시)
- `source: 'settings'` 플러그인 마켓플레이스 소스 추가 - settings.json에 인라인 선언 가능
- 스킬/슬래시 명령에 `effort` frontmatter 지원 추가
- `--channels` (연구 프리뷰) - MCP 서버가 세션에 메시지 푸시 가능

### 버그 수정
- `--resume`에서 병렬 도구 결과 누락 수정
- 음성 모드 WebSocket 실패 (Cloudflare 봇 탐지) 수정
- fine-grained 도구 스트리밍 시 API 프록시/Bedrock/Vertex에서 400 에러 수정

### 성능 개선
- 대형 저장소 시작 시 메모리 사용량 약 80MB 절감 (250k 파일 기준)

---

## v2.1.79 주요 변경사항 (2026-03-18)

### 새 기능
- `claude auth login`에 `--console` 플래그 추가 (Anthropic Console API 빌링 인증용)
- `/config` 메뉴에 "Show turn duration" 토글 추가
- `CLAUDE_CODE_PLUGIN_SEED_DIR`이 다중 시드 디렉토리 지원 (Unix `:`, Windows `;` 구분)
- [VSCode] `/remote-control` 추가 - 세션을 claude.ai/code에 브릿지하여 브라우저/폰에서 계속 가능
- [VSCode] 세션 탭에 AI 생성 제목 부여

### 버그 수정
- `claude -p`가 명시적 stdin 없이 서브프로세스로 실행 시 행 걸리는 문제 수정
- `-p` 모드에서 Ctrl+C 작동 안 하던 문제 수정
- 엔터프라이즈 사용자가 429 에러 시 재시도 불가하던 문제 수정

### 성능 개선
- 시작 시 메모리 사용량 약 18MB 절감

---

## 출처
- [GitHub Releases](https://github.com/anthropics/claude-code/releases)
- [npm @anthropic-ai/claude-code](https://www.npmjs.com/package/@anthropic-ai/claude-code)
- [Claude Code Changelog](https://code.claude.com/docs/en/changelog)
