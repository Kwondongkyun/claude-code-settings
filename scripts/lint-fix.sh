#!/bin/bash
FILE="$1"

# .ts/.tsx/.js/.jsx/.mjs 파일만 처리
if [[ ! "$FILE" =~ \.(ts|tsx|js|jsx|mjs)$ ]]; then
  exit 0
fi

# 프로젝트 루트 찾기 (package.json 위치)
DIR=$(dirname "$FILE")
while [[ "$DIR" != "/" ]]; do
  if [[ -f "$DIR/package.json" ]]; then
    break
  fi
  DIR=$(dirname "$DIR")
done

# ESLint --fix 실행 (수정 불가한 에러는 무시)
cd "$DIR" && npx eslint --fix "$FILE" 2>/dev/null

exit 0
