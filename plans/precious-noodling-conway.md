# Amplify 배포 완료 → Slack 알림 (Claude Code Hook)

## Context
프론트엔드 프로젝트들이 AWS Amplify에 배포 중인데, 현재는 AWS 콘솔에서 직접 배포 상태를 확인하고 있음. Claude Code에서 `git push` 후 자동으로 배포 상태를 모니터링하고 Slack으로 결과를 알려주는 hook을 구성한다.

## 사전 준비: Slack Incoming Webhook
1. https://api.slack.com/apps → Create New App → From Scratch
2. Incoming Webhooks 활성화 → Add New Webhook to Workspace → 채널 선택
3. Webhook URL 복사 → `~/.claude/slack-webhook-url` 파일에 저장
4. 사용자에게 URL 입력 받아 파일 생성

## 구현

### 1. `~/.claude/slack-webhook-url` (신규)
- Slack Webhook URL 한 줄 저장

### 2. `~/.claude/amplify-deploy-watch.sh` (신규)

**동작 흐름:**
```
1. $CLAUDE_TOOL_INPUT에서 command 추출
2. git push 명령이 아니면 즉시 exit 0
3. 현재 작업 디렉토리에서 git remote URL 추출
4. aws amplify list-apps --profile eren 으로 remote URL → appId 매핑
5. 매핑 실패 시 (Amplify에 없는 프로젝트) 조용히 exit 0
6. 현재 브랜치명 추출
7. 백그라운드 서브프로세스로 폴링 시작 (exit 0 즉시 반환)
   - 30초 간격으로 aws amplify list-jobs 조회
   - PENDING/RUNNING 상태면 계속 폴링
   - SUCCEED/FAILED/CANCELLED 이면 Slack webhook 전송
   - 최대 15분 타임아웃
```

**Slack 메시지 포맷:**
- 성공: `✅ [앱이름] <브랜치> 배포 완료 (소요시간)` + Amplify 콘솔 링크
- 실패: `❌ [앱이름] <브랜치> 배포 실패` + Amplify 콘솔 링크

**핵심 사항:**
- `nohup ... &`로 백그라운드 실행 → Claude Code 블로킹 없음
- `~/.claude/amplify-watch.log`에 로그 기록
- AWS 프로필: `eren`
- 리전: Amplify 앱의 리전 (list-apps에서 확인)

### 3. `~/.claude/settings.json` 수정

기존 hooks에 PostToolUse 추가:
```json
"PostToolUse": [
  {
    "matcher": "Bash",
    "hooks": [
      {
        "type": "command",
        "command": "bash ~/.claude/amplify-deploy-watch.sh"
      }
    ]
  }
]
```

## 수정 대상 파일
- `~/.claude/slack-webhook-url` — 신규 생성
- `~/.claude/amplify-deploy-watch.sh` — 신규 생성 (chmod +x)
- `~/.claude/settings.json:57` — hooks 객체에 PostToolUse 배열 추가

## 검증
1. `curl`로 Slack webhook 테스트 메시지 전송하여 연결 확인
2. Amplify 앱이 있는 프로젝트에서 `git push` 실행
3. `tail -f ~/.claude/amplify-watch.log`로 폴링 동작 확인
4. 배포 완료 후 Slack 채널에 알림 도착 확인
