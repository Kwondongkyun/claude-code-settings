#!/bin/bash
# UserPromptSubmit 훅: compact 마커 감지 시 리마인더 주입
MARKER="/tmp/.claude-compacted"

if [ -f "$MARKER" ]; then
  rm "$MARKER"
  echo '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"[COMPACT 복구] compact가 발생했습니다. plan.md, progress.md, memory.md, findings.md를 읽고 현재 작업 컨텍스트를 파악하세요."}}'
fi
