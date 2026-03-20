#!/bin/bash
LOG=~/.claude/notify.log
TYPE=$(echo "$1" | tr '[:lower:]' '[:upper:]')  # Asks → ASKS, Stops → STOPS

front_app=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)
control_client=$(tmux list-clients -F '#{client_name} #{client_control_mode}' 2>/dev/null | awk '$2 == "1" {print $1; exit}')
client_window=$(tmux display-message -c "$control_client" -p '#{window_index}' 2>/dev/null)
my_window=$(tmux display-message -t "$TMUX_PANE" -p '#{window_index}' 2>/dev/null)

{
  echo "--- $(date) ---"
  echo "type: $TYPE"
  echo "front_app: $front_app"
  echo "control_client: $control_client"
  echo "client_window: $client_window"
  echo "my_window: $my_window"
  echo "TMUX_PANE: $TMUX_PANE"
} >> "$LOG"

if [ "$front_app" = "iTerm2" ] && [ "$client_window" = "$my_window" ]; then
  echo "→ exit 0 (same tab)" >> "$LOG"
  exit 0
fi

pane_tty=$(tmux display-message -t "$TMUX_PANE" -p '#{pane_tty}')
echo "→ sending OSC9 notify ($TYPE) to $pane_tty" >> "$LOG"
printf '\ePtmux;\e\e]9;Claude %s\a\e\\' "$1" > "$pane_tty"
