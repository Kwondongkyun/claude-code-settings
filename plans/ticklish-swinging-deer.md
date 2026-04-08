# 제안서 초안 DOCX 파일 생성 기능

## Context
현재 `_draft_proposal`은 Bedrock Claude가 생성한 제안서 초안을 텍스트로 반환하고, agent의 Claude가 이를 다시 요약해서 Slack에 전달함. 사용자가 원하는 것은 **제안서 초안을 DOCX(Word) 파일로 생성하여 Slack 스레드에 업로드**하는 것.

## 현재 흐름 (문제)
```
사용자: "제안서 초안 작성해줘"
  → Lambda agent Claude → draft_proposal tool 호출
  → Bedrock Claude가 초안 텍스트 생성
  → agent Claude가 텍스트를 받아서 요약(!)해버림
  → Slack에 요약만 전달됨
```

## 변경 후 흐름
```
사용자: "제안서 초안 작성해줘"
  → Lambda agent Claude → draft_proposal tool 호출
  → Bedrock Claude가 초안을 구조화된 JSON으로 생성
  → python-docx로 DOCX 파일 생성 (/tmp/)
  → Slack 스레드에 DOCX 파일 업로드
  → tool 결과로 "제안서 초안 파일을 업로드했습니다" 반환
```

## 수정 사항

### 1. `requirements.txt` — python-docx 추가
```
python-docx>=1.1.0
```

### 2. `app/docx_generator.py` — 신규 파일
DOCX 제안서 생성 모듈.

```python
def generate_proposal_docx(sections: list[dict], metadata: dict) -> Path:
```

- Bedrock 응답(JSON)을 받아서 python-docx로 DOCX 생성
- 구조: 표지 → 목차 → 각 섹션(제목 + 본문)
- 스타일: 제목(Heading), 본문(Normal), 표 등
- 파일 저장: `/tmp/{bid_ntce_no}_proposal.docx`
- 반환: 생성된 파일 경로

### 3. `app/slack/agent_executor.py` — `_draft_proposal` 수정

**변경 핵심:**
1. Bedrock 프롬프트를 JSON 구조로 응답하도록 변경
2. 응답을 파싱하여 `generate_proposal_docx()` 호출
3. `send_thread_file()`로 Slack 스레드에 DOCX 업로드
4. 텍스트 대신 "파일 업로드 완료" 메시지 반환

**필요 추가 파라미터:** `channel_id`, `thread_ts` (파일 업로드용)
- `execute_tool()`에서 전달받아야 함
- 또는 `_draft_proposal` 내부에서 SlackNotification 테이블로 조회

**Bedrock 프롬프트 변경:**
```
다음 입찰공고에 대한 제안서 초안을 JSON 형식으로 작성해주세요.

반환 형식:
{
  "title": "사업명",
  "sections": [
    {
      "heading": "1. 제안 개요",
      "subsections": [
        {
          "subheading": "1.1 사업 배경 및 목적",
          "content": "본문 내용..."
        }
      ]
    }
  ]
}
```

### 4. `app/slack/agent_executor.py` — `execute_tool` 수정
`draft_proposal` 호출 시 `channel_id`, `thread_ts`를 전달할 수 있도록 확장.

### 5. `app/slack/agent.py` — tool_use 결과 처리
`_call_claude_with_tools()`에서 `channel_id`, `thread_ts`를 `execute_tool()`에 전달.

## 수정 파일 요약

| 파일 | 변경 내용 |
|------|---------|
| `requirements.txt` | `python-docx>=1.1.0` 추가 |
| `app/docx_generator.py` | **신규** — DOCX 제안서 생성 |
| `app/slack/agent_executor.py` | `_draft_proposal` 수정 — JSON 응답 + DOCX 생성 + 파일 업로드 |
| `app/slack/agent.py` | `execute_tool`에 channel_id, thread_ts 전달 |

## 기존 코드 재사용
- `bedrock_client.py:get_bedrock_client()` — Bedrock 클라이언트
- `notifier.py:send_thread_file()` — Slack 스레드 파일 업로드
- `config.py:get_settings()` — 설정
- `agent_executor.py:_get_thread_url()` — SlackNotification에서 thread 정보 조회

## 검증 방법
1. EC2에서 수동 테스트: 특정 bid_ntce_no로 `_draft_proposal` 호출 → DOCX 생성 확인
2. Lambda 배포 후 Slack에서 `@2PM 제안서 초안 작성해줘` → DOCX 파일 업로드 확인
3. 생성된 DOCX를 한글(HWP)에서 열어보기
