#!/bin/bash
# stall-detector.sh — score-history.jsonl에서 점수 정체 여부를 판단
# 사용법: bash stall-detector.sh [score-history.jsonl 경로]
#
# 출력: PROGRESSING / STALL / REGRESSING / INSUFFICIENT
# STALL = 최근 3회 연속 delta ±2점 이내 → pivot 필요

SCORE_FILE=${1:-"score-history.jsonl"}
THRESHOLD=2

if [ ! -f "$SCORE_FILE" ]; then
  echo "INSUFFICIENT"
  echo "# score-history.jsonl not found: $SCORE_FILE" >&2
  exit 0
fi

LINE_COUNT=$(wc -l < "$SCORE_FILE" | tr -d ' ')

if [ "$LINE_COUNT" -lt 3 ]; then
  echo "INSUFFICIENT"
  echo "# Need at least 3 iterations, got $LINE_COUNT" >&2
  exit 0
fi

# 최근 3개 점수 추출
SCORES=$(tail -3 "$SCORE_FILE" | while read -r line; do
  echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin)['total'])" 2>/dev/null
done)

S1=$(echo "$SCORES" | sed -n '1p')
S2=$(echo "$SCORES" | sed -n '2p')
S3=$(echo "$SCORES" | sed -n '3p')

if [ -z "$S1" ] || [ -z "$S2" ] || [ -z "$S3" ]; then
  echo "INSUFFICIENT"
  echo "# Failed to parse scores" >&2
  exit 0
fi

# delta 계산
D1=$(echo "scale=1; $S2 - $S1" | bc)
D2=$(echo "scale=1; $S3 - $S2" | bc)

# 절대값
ABS_D1=$(echo "$D1" | tr -d '-')
ABS_D2=$(echo "$D2" | tr -d '-')

echo "# Scores: $S1 → $S2 → $S3 (delta: $D1, $D2)" >&2

# 판정
# STALL: 두 delta 모두 ±THRESHOLD 이내
STALL_D1=$(echo "$ABS_D1 <= $THRESHOLD" | bc)
STALL_D2=$(echo "$ABS_D2 <= $THRESHOLD" | bc)

if [ "$STALL_D1" -eq 1 ] && [ "$STALL_D2" -eq 1 ]; then
  echo "STALL"
  exit 0
fi

# REGRESSING: 두 delta 모두 음수이고 THRESHOLD 초과
NEG_D1=$(echo "$D1 < -$THRESHOLD" | bc)
NEG_D2=$(echo "$D2 < -$THRESHOLD" | bc)

if [ "$NEG_D1" -eq 1 ] && [ "$NEG_D2" -eq 1 ]; then
  echo "REGRESSING"
  exit 0
fi

echo "PROGRESSING"
