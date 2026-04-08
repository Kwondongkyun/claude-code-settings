# Claude Code 업데이트 확인 결과

> 확인 일시: 2026-03-23

## 현재 상태

| 항목 | 값 |
|------|-----|
| **설치된 버전** | 2.1.81 |
| **최신 버전 (latest)** | 2.1.81 |
| **안정 버전 (stable)** | 2.1.74 |
| **next 태그** | 2.1.81 |
| **업데이트 필요 여부** | 아니오 (최신 버전 사용 중) |

## 최근 릴리스 타임라인

| 버전 | 릴리스 날짜 |
|------|-------------|
| 2.1.81 | 2026-03-20 |
| 2.1.80 | 2026-03-19 |
| 2.1.79 | 2026-03-18 |
| 2.1.78 | 2026-03-17 |
| 2.1.77 | 2026-03-16 |
| 2.1.76 | 2026-03-14 |
| 2.1.75 | 2026-03-13 |
| 2.1.74 | 2026-03-11 |
| 2.1.73 | 2026-03-11 |
| 2.1.72 | 2026-03-09 |

---

## 버전별 주요 변경사항

### v2.1.81 (2026-03-20) -- 현재 설치 버전

**새 기능:**
- `--bare` 플래그 추가 (스크립트된 `-p` 호출용, 훅/LSP/플러그인 동기화 건너뜀)
- `--channels` 권한 중계 기능 추가 (도구 승인을 전화로 전달)

**버그 수정:**
- 여러 OAuth 토큰 재인증 문제 수정
- 음성 모드 WebSocket 연결 끊김 복구 개선
- `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS`가 structured-outputs 베타 헤더 억제 안 되던 문제 수정
- 플러그인 훅이 디렉토리 삭제 시 프롬프트 제출 차단하던 문제 수정

**개선:**
- MCP read/search 도구 호출이 한 줄로 축약 표시
- `!` bash 모드 검색 가능성 개선
- ref-tracked 플러그인이 로드 시 재클론되어 최신 상태 유지
- MCP OAuth가 Client ID Metadata Document (CIMD / SEP-991) 지원

**플랫폼:**
- Windows/WSL에서 라인별 응답 스트리밍 비활성화 (렌더링 이슈)
- [VSCode] Windows PATH 상속 문제 수정 (Git Bash용 Bash 도구)

---

### v2.1.80 (2026-03-19)

**새 기능:**
- `rate_limits` 필드 추가 (상태 표시줄 스크립트에서 Claude.ai 요금 제한 사용량 표시)
- `source: 'settings'` 플러그인 마켓플레이스 소스 추가 (settings.json 인라인 플러그인)
- CLI 도구 사용 감지 기능으로 플러그인 팁 표시
- 스킬/슬래시 명령에 `effort` frontmatter 지원
- `--channels` (연구 프리뷰) MCP 서버가 세션에 메시지 푸시 가능

**버그 수정:**
- `--resume` 시 병렬 도구 결과 손실 수정
- 음성 모드 Cloudflare 봇 감지 WebSocket 실패 수정
- 프록시를 통한 세분화된 도구 스트리밍 400 에러 수정
- `/remote-control`이 게이트웨이 배포에서 표시되던 문제 수정
- `/sandbox` 탭 전환 키보드 네비게이션 수정
- 캐시된 remote-settings.json에서 관리 설정이 시작 시 적용 안 되던 문제 수정

**개선:**
- `@` 파일 자동완성 응답성 향상 (대규모 저장소)
- `/effort`가 auto 해석 결과 표시
- 시작 시 메모리 사용량 ~80 MB 절감 (250k 파일 저장소)

---

### v2.1.79 (2026-03-18)

**새 기능:**
- `claude auth login`에 `--console` 플래그 추가 (Anthropic Console 인증용)
- `/config` 메뉴에 "턴 지속 시간 표시" 토글 추가
- [VSCode] `/remote-control` 추가 (세션을 claude.ai/code로 브리지)
- [VSCode] 세션 탭에 AI 생성 제목 부여

**버그 수정:**
- `claude -p`가 명시적 stdin 없이 서브프로세스로 실행 시 행(hang) 수정
- `-p` (print) 모드에서 Ctrl+C 작동 안 하던 문제 수정
- `/btw`가 사이드 질문 대신 메인 에이전트 출력 반환하던 문제 수정
- 음성 모드가 `voiceEnabled: true`로 시작 시 제대로 활성화 안 되던 문제 수정
- 기업 사용자가 요금 제한(429) 오류 시 재시도 불가하던 문제 수정
- `SessionEnd` 훅이 대화형 `/resume`에서 발생 안 되던 문제 수정

**개선:**
- 시작 시 메모리 사용량 ~18MB 개선
- 비스트리밍 API 폴백에 2분 타임아웃 추가
- `CLAUDE_CODE_PLUGIN_SEED_DIR`이 여러 디렉토리 지원

---

### v2.1.78 (2026-03-17)

**새 기능:**
- `StopFailure` 훅 이벤트 추가 (API 오류 처리용)
- `${CLAUDE_PLUGIN_DATA}` 변수 추가 (플러그인 지속 상태)
- 플러그인 제공 에이전트에 `effort`, `maxTurns`, `disallowedTools` frontmatter 추가
- `ANTHROPIC_CUSTOM_MODEL_OPTION` 환경 변수 추가 (커스텀 `/model` 선택기 항목)

**버그 수정:**
- `git log HEAD`가 Linux 샌드박스 Bash에서 "ambiguous argument" 실패 수정
- `cc log` 및 `--resume`가 대규모 세션(>5 MB) 조용히 잘림 수정
- API 오류가 stop 훅을 트리거할 때 무한 루프 수정
- `deny: ["mcp__servername"]` 규칙이 MCP 서버 도구 제거 안 하던 문제 수정
- `sandbox.filesystem.allowWrite`가 절대 경로에서 작동 안 하던 문제 수정

**보안:**
- 샌드박스 자동 비활성화 시 시작 경고 추가
- `bypassPermissions` 모드에서 보호 디렉토리가 프롬프트 없이 쓰기 가능하던 문제 수정

**개선:**
- 응답 텍스트가 생성되는 대로 라인별 스트리밍
- tmux에서 터미널 알림이 외부 터미널에 도달 (`set -g allow-passthrough on`)
- 대규모 세션 재개 시 메모리 사용량 및 시작 시간 개선

---

### v2.1.77 (2026-03-16)

**새 기능:**
- Claude Opus 4.6 기본 최대 출력 토큰 64k, 상한 128k로 증가
- `allowRead` 샌드박스 파일시스템 설정 추가 (읽기 접근 재허용)
- `/copy N`으로 N번째 최근 응답 복사 지원

**주요 버그 수정:**
- 복합 bash 명령에 "Always Allow" 시 전체 문자열에 단일 규칙 저장하던 문제 수정
- 자동 업데이터가 중복 다운로드 시작하며 메모리 누적 문제 수정
- `--resume`가 최근 히스토리 조용히 잘림 수정
- CJK 문자가 인접 UI 요소에 번짐 수정
- tmux에서 배경색이 터미널 기본값으로 렌더링 수정

**성능:**
- 세션 대규모 메모리 누수 개선 (fork 많은 세션에서 최대 45% 빠른 로드, ~100-150MB 피크 메모리 감소)
- macOS에서 ~60ms 빠른 시작 (병렬 키체인 읽기)

**기타:**
- `/fork`가 `/branch`로 이름 변경 (별칭 유지)
- 백그라운드 bash 태스크 출력 5GB 초과 시 종료
- 세션이 plan 내용에서 자동 이름 부여

---

### v2.1.76 (2026-03-14)

**새 기능:**
- MCP 유도(Elicitation) 지원 추가 (구조화된 입력 대화형 다이얼로그)
- `Elicitation` 및 `ElicitationResult` 훅 추가
- `-n` / `--name <name>` CLI 플래그 추가 (시작 시 표시 이름 설정)
- `worktree.sparsePaths` 설정 추가 (대규모 모노레포용 git sparse-checkout)
- `PostCompact` 훅 추가 (압축 완료 후)
- `/effort` 슬래시 명령 추가 (모델 노력 수준 설정)
- 세션 품질 설문조사 추가

**버그 수정:**
- 지연된 도구가 압축 후 입력 스키마 손실 수정
- 슬래시 명령이 "Unknown skill" 표시 수정
- 계획 모드가 수락 후 재승인 요청 수정
- 자동 압축이 무한 재시도 (3회 후 회로 차단기)

**개선:**
- `--worktree` 시작 개선 (직접 git refs, 불필요한 fetch 건너뜀)
- 모델 폴백 알림 개선 (항상 표시, 사람 친화적 이름)
- 인용문 가독성 개선 (왼쪽 바 + 이탤릭)

---

### v2.1.75 (2026-03-13)

**새 기능:**
- Opus 4.6에 1M 컨텍스트 윈도우 기본 제공 (Max/Team/Enterprise 플랜)
- `/color` 명령 추가 (세션별 프롬프트 바 색상 설정)
- `/rename`으로 세션 이름 표시
- 메모리 파일에 마지막 수정 타임스탬프 추가
- 훅 소스 표시 (settings/plugin/skill)

**버그 수정:**
- 음성 모드가 신규 설치에서 활성화 안 되던 문제 수정
- 스트리밍 API 응답 버퍼 메모리 누수 수정
- 관리 비활성화 플러그인이 `/plugin` Installed 탭에 표시되던 문제 수정
- 토큰 추정이 thinking/tool_use 블록을 과다 계산하던 문제 수정

**파괴적 변경:**
- Windows 관리 설정 폴백 `C:\\ProgramData\\ClaudeCode\\managed-settings.json` 제거

---

### v2.1.74 (2026-03-11)

**새 기능:**
- `/context` 명령에 실행 가능한 제안 추가 (컨텍스트 과다 도구, 메모리 비대, 용량 경고)
- `autoMemoryDirectory` 설정 추가 (커스텀 자동 메모리 저장 위치)

**버그 수정:**
- 스트리밍 API 응답 버퍼 메모리 누수 수정
- 관리 정책 `ask` 규칙이 사용자 `allow` 규칙에 의해 우회되던 문제 수정
- MCP OAuth 콜백 포트 사용 중 행(hang) 수정
- 음성 모드가 macOS 네이티브 바이너리에서 마이크 권한 없이 실패 수정
- 히브리어/아랍어/RTL 텍스트가 Windows Terminal에서 렌더링 안 되던 문제 수정

---

### v2.1.73 (2026-03-11)

**새 기능:**
- `modelOverrides` 설정 추가 (모델 선택기 항목을 커스텀 프로바이더 모델 ID에 매핑)

**버그 수정:**
- 복잡한 Bash 명령 권한 프롬프트에서 100% CPU 루프/프리즈 수정
- 여러 스킬 파일 동시 변경 시 데드락 수정
- Bash 도구 출력이 같은 디렉토리의 여러 세션에서 손실 수정
- 서브에이전트가 Bedrock/Vertex/Foundry에서 `model: opus/sonnet/haiku` 시 조용히 다운그레이드 수정
- Linux 샌드박스에서 "ripgrep not found" 실패 수정

**개선:**
- `/effort`가 Claude 응답 중에도 작동
- Bedrock/Vertex/Foundry 기본 Opus가 Opus 4.6으로 변경
- `/output-style` 명령 폐기 예정 (대신 `/config` 사용)

---

### v2.1.72 (2026-03-09)

**새 기능:**
- `/copy`에 `w` 키 추가 (파일에 직접 쓰기, SSH에서 유용)
- `/plan`에 선택적 설명 인수 지원 (즉시 시작)
- `ExitWorktree` 도구 추가
- `CLAUDE_CODE_DISABLE_CRON` 환경 변수 추가 (예약 작업 중지)
- Agent 도구에 `model` 파라미터 복원 (호출별 오버라이드)

**버그 수정:**
- 여러 권한 규칙 일치 문제 수정
- 백그라운드 태스크/훅으로 느린 종료 수정
- 에이전트 태스크 진행이 "Initializing..." 멈춤 수정
- 음성 모드 지연, 거짓 "No speech" 오류, 오래된 트랜스크립트 수정
- 프롬프트 캐시 무효화 수정 (SDK `query()`에서 입력 토큰 최대 12배 감소)

**개선:**
- 노력 수준 단순화 (low/medium/high, max 제거)
- 번들 크기 ~510 KB 감소
- CLAUDE.md HTML 주석이 Claude에게 숨겨짐 (Read 도구에서는 표시)

---

## 요약

현재 설치된 Claude Code **v2.1.81**은 npm 레지스트리의 **최신 버전(latest)**과 동일합니다. 업데이트가 필요하지 않습니다.

최근 2주간(v2.1.72~v2.1.81) 주요 트렌드:
1. **성능 최적화**: 시작 시 메모리 사용량 대폭 감소, 세션 로드 속도 개선
2. **음성 모드 안정화**: WebSocket, Cloudflare, 크로스 플랫폼 호환성 지속 수정
3. **플러그인 생태계 확장**: 마켓플레이스, frontmatter 지원, 훅 시스템 강화
4. **Opus 4.6 최적화**: 1M 컨텍스트 윈도우, 64k/128k 출력 토큰, 기본 모델 전환
5. **보안 강화**: 샌드박스 경고, 권한 규칙 수정, 관리 정책 우선순위 수정
