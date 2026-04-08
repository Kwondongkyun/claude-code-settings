---
description: Score 정체 감지 및 방향 전환(pivot) 판단
argument-hint: <score-history.jsonl 경로>
effort: medium
---

한국어로 응답하세요.

## 파일 탐색

- `$ARGUMENTS`가 있으면 해당 경로의 `score-history.jsonl` 사용
- 없으면 현재 디렉토리 및 `docs/specs/*/score-history.jsonl` 탐색

## 실행 순서

### 1단계: Stall Detection

```bash
bash ~/.claude/scripts/stall-detector.sh <score-history.jsonl 경로>
```

결과를 읽는다.

### 2단계: 결과별 대응

**INSUFFICIENT:**
- "데이터 부족 (3회 이상 평가 필요)" 안내
- 현재까지의 점수 이력 표시

**PROGRESSING:**
- "점수가 개선 중입니다. 현재 방향을 유지하세요." 안내
- 최근 3회 점수 추이 시각화
- 다음 iteration에서 집중할 개선 포인트 제안

**STALL:**
- 경고: "3회 연속 점수 정체 (±2점). Pivot을 권장합니다."
- 현재 접근 방식 요약 (handoff.md 또는 최근 커밋 기반)
- AskUserQuestion으로 3가지 대안 제시:
  1. **UI 구조 변경** — 레이아웃/컴포넌트 구조를 근본적으로 재설계
  2. **기술 접근 변경** — 다른 라이브러리/패턴 시도
  3. **스코프 축소** — 핵심 기능에 집중, 나머지 제거
- 사용자 선택 후:
  - handoff.md에 `## PIVOT` 섹션 추가: `[이전 접근] → [새 접근]`
  - score-history.jsonl에 `"pivot":true` 마커 추가

**REGRESSING:**
- 경고: "점수가 하락 중입니다. 최근 변경을 되돌리거나 Pivot이 필요합니다."
- `git log --oneline -5`로 최근 변경 표시
- 되돌리기 vs Pivot 선택 요청

### 3단계: 점수 이력 시각화

```
Score History:
  Iter 1: ████████████████████░░░░░  52.0
  Iter 2: █████████████████████████░  65.5  (+13.5)
  Iter 3: ██████████████████████████  77.5  (+12.0)
  Iter 4: ██████████████████████████  78.0  (+0.5) ← STALL
  Iter 5: ██████████████████████████  77.8  (-0.2) ← STALL
  Iter 6: ██████████████████████████  78.2  (+0.4) ← STALL → PIVOT
```

## 주의사항

- Pivot은 "포기"가 아니라 "새로운 시도". Anthropic 사례에서 10번째 iteration의 pivot이 창의적 도약을 만들어냄
- Pivot 후에도 score-history.jsonl은 리셋하지 않고 이어서 기록 (추세를 볼 수 있도록)
- handoff.md의 "시도했으나 실패한 접근"에 이전 방법을 기록하여 같은 실수 방지
