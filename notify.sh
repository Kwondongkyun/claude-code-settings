#!/bin/bash
TYPE="$1"

front_app=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)

# 터미널이 포커스 중이면 알림 스킵
if [ "$front_app" = "iTerm2" ] || [ "$front_app" = "Terminal" ]; then
  exit 0
fi

osascript -e "display notification \"Claude $TYPE\" with title \"Claude Code\""
