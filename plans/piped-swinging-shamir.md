# 세션 카드에 시간 + 토큰 정보 추가

## Context
현재 세션 카드: `제목 + 상대시간 / 브랜치 · 메시지수` 2줄 구조.
JSONL의 `timestamp`와 `message.usage`를 파싱하여 세션 소요 시간 및 토큰 사용량을 카드에 추가.

## 변경 파일

### 1. `Sources/Models/Session.swift`
- `duration: TimeInterval?` 추가 (초 단위)
- `totalInputTokens: Int` 추가
- `totalOutputTokens: Int` 추가
- `formattedDuration` computed property (예: "1시간 23분", "5분")
- `formattedTokens` computed property (예: "12.3K in · 4.5K out")

### 2. `Sources/Services/SessionParser.swift`
전체 파일은 이미 읽고 있으므로(`readDataToEndOfFile()`) 추가 I/O 없음.

fullData → String 변환 후 라인별 JSON 파싱:
- `timestamp` min/max → duration 계산
- `type == "assistant"`의 `message.usage`에서 토큰 합산
  - input: `input_tokens + cache_creation_input_tokens + cache_read_input_tokens`
  - output: `output_tokens`
- `"role"` 포함 라인 카운트 → messageCount (기존 `countOccurrences` 대체)

### 3. `Sources/Views/MainView.swift`
`sessionInfoParts` 함수 확장:
```
제목                                    상대시간
브랜치 · 210 messages · 1시간 23분 · 12.3K tokens
```
데이터 없으면 해당 부분 생략.

## 검증
1. `swift build` 성공
2. devfeed 프로젝트에서 시간/토큰 표시 확인
3. 대용량 세션(25MB)에서 UI 멈춤 없는지 확인
