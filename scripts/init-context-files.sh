#!/bin/bash
# SessionStart 훅: plan.md, progress.md, memory.md 없으면 템플릿에서 복사
TEMPLATE_DIR="$HOME/.claude/templates"
TODAY=$(date +%Y-%m-%d)

for file in plan.md progress.md memory.md findings.md; do
  if [ ! -f "$file" ]; then
    sed "s/{{DATE}}/$TODAY/g" "$TEMPLATE_DIR/$file" > "$file"
  fi
done
