# 제출 문서 목록 추출 + 수집 완료 요약 알림

## Context
1. 상세 분석 시 타당성/제안포인트/경고만 추출 → **제출 문서 목록**도 함께 추출 필요
2. 수집 후 유사도 70% 이상 건이 없으면 Slack 알림이 전혀 없음 → 사용자가 정상인지 오류인지 구분 불가 → **수집 완료 요약 메시지** 필요

> 제안서 초안 HWP 파일 생성은 보류 (사용자 결정)

---

## 수정 파일 (2개)

### 1. `app/ai_analyzer.py` - `analyze_order_plan_detailed()` 프롬프트 수정

**변경 위치**: 293~318행 프롬프트의 JSON 응답 스키마

**추가할 필드:**
```json
"required_documents": ["제안서 (10부)", "가격제안서", "사업수행계획서", "..."]
```

**프롬프트 지시사항 추가:**
> "required_documents": 제안요청서/과업지시서에서 제안 업체가 제출해야 하는 문서 목록을 추출. 제안서, 가격제안서, 사업수행계획서, 경영상태확인원, 참가자격증명서 등 모든 제출 서류를 나열. 부수/형식 요건이 있으면 괄호로 표기. 찾을 수 없으면 빈 배열.

**fallback dict (358행)에도 추가:** `"required_documents": []`

### 2. `app/slack/messages.py` - `create_detailed_analysis_message()` 렌더링 추가

**변경 위치**: 324~366행 함수 내부, warnings 블록 다음에 추가

```python
docs = analysis.get('required_documents', [])
if docs:
    message_parts.append("")
    message_parts.append("*📋 제출 문서 목록*")
    for i, doc in enumerate(docs, 1):
        message_parts.append(f"{i}. {doc}")
```

---

## 영향 범위
- DB 변경 없음
- 기존 JSON 필드에 optional 필드 추가이므로 하위 호환 유지
- `analyze_order_plan_detailed()`를 호출하는 곳: `notifier.py:analyze_and_reply_attachments()` → 기존 흐름 그대로

---

## 기능 3: 수집 완료 요약 알림

### 문제
- `scheduled_data_collection_job()` (매일 새벽 3시): 수집 → `send_bulk_notifications(min_similarity=0.7)` → 유사도 70% 이상 없으면 Slack에 아무것도 안 옴
- `lambda_notification.py` (60분마다): 동일 문제
- 사용자는 "시스템이 정상인지, 오류인지" 구분 불가

### 수정 파일 (2개)

#### 1. `app/slack/notifier.py` - `send_collection_summary()` 함수 추가

```python
def send_collection_summary(
    collection_result: dict,
    notification_result: dict,
    channel_id: str = None
) -> bool:
    """수집 + 알림 완료 요약을 Slack에 전송"""
```

**메시지 예시 (알림 대상 있을 때):**
```
✅ 데이터 수집 완료
• 수집: 1,234건 (신규 5, 업데이트 12)
• 입찰공고: 3건 수집
• 알림 전송: 2건
```

**메시지 예시 (알림 대상 없을 때):**
```
✅ 데이터 수집 완료
• 수집: 1,234건 (신규 0, 업데이트 8)
• 입찰공고: 0건 수집
📭 유사도 70% 이상 신규 알림 대상이 없습니다.
```

- 기존 `get_slack_client()`, `settings.slack_channel_id` 재사용
- 오류 발생 시에도 요약 메시지 전송 (오류 내용 포함)

#### 2. `app/main.py` - `scheduled_data_collection_job()` 수정

수집과 알림 완료 후 `send_collection_summary()` 호출:
```python
def scheduled_data_collection_job():
    # ... 기존 수집 + 알림 로직 ...

    from app.slack.notifier import send_collection_summary
    send_collection_summary(
        collection_result=result,  # collect_order_plans 반환값
        notification_result=notif_result  # send_bulk_notifications 반환값
    )
```

수집 실패 시에도 오류 요약 전송:
```python
except Exception as e:
    send_collection_summary(
        collection_result={"error": str(e)},
        notification_result={"total": 0, "sent": 0}
    )
```

> **참고**: `lambda_notification.py`는 60분마다 실행되므로 매번 요약을 보내면 노이즈가 됨.
> Lambda에는 추가하지 않고, 매일 새벽 스케줄 작업에서만 요약 전송.

---

## 전체 수정 파일 요약

| # | 파일 | 변경 내용 |
|---|------|----------|
| 1 | `app/ai_analyzer.py` | `analyze_order_plan_detailed()` 프롬프트에 `required_documents` 추가 |
| 2 | `app/slack/messages.py` | `create_detailed_analysis_message()`에 제출 문서 목록 렌더링 |
| 3 | `app/slack/notifier.py` | `send_collection_summary()` 함수 추가 |
| 4 | `app/main.py` | `scheduled_data_collection_job()`에서 요약 메시지 전송 |

## 검증 방법
1. **제출 문서 추출**: 첨부파일 있는 입찰공고의 상세 분석 스레드 → "📋 제출 문서 목록" 섹션 표시 확인
2. **제출 문서 없는 경우**: 해당 섹션이 표시되지 않는지 확인
3. **수집 요약 알림**: `POST /order-plans/collect` 후 `POST /slack/notifications/bulk` 호출 → Slack 채널에 요약 메시지 도착 확인
4. **알림 대상 0건**: 유사도 70% 이상 신규 건이 없을 때 "📭 알림 대상 없습니다" 메시지 확인
