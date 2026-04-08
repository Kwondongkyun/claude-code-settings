#!/bin/bash
# eval-score-log.sh — evaluator 점수를 score-history.jsonl에 기록
# 사용법: bash eval-score-log.sh <iteration> <functionality> <design> <code> <polish> [output-dir]
#
# 예시: bash eval-score-log.sh 1 85 60 90 70
# 예시: bash eval-score-log.sh 2 90 75 95 80 docs/specs/login

ITERATION=${1:?"Usage: eval-score-log.sh <iteration> <func> <design> <code> <polish> [dir]"}
FUNC=${2:?}
DESIGN=${3:?}
CODE=${4:?}
POLISH=${5:?}
OUTPUT_DIR=${6:-.}

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 가중 평균 계산 (func 40% + design 25% + code 20% + polish 15%)
TOTAL=$(echo "scale=1; $FUNC * 0.4 + $DESIGN * 0.25 + $CODE * 0.2 + $POLISH * 0.15" | bc)

# JSONL에 append
echo "{\"iteration\":$ITERATION,\"timestamp\":\"$TIMESTAMP\",\"scores\":{\"functionality\":$FUNC,\"design\":$DESIGN,\"code\":$CODE,\"polish\":$POLISH},\"total\":$TOTAL}" >> "$OUTPUT_DIR/score-history.jsonl"

echo "Score logged: iteration=$ITERATION total=$TOTAL (func=$FUNC design=$DESIGN code=$CODE polish=$POLISH)"
