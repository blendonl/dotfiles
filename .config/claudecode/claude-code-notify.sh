#!/usr/bin/env bash

INPUT=$(cat)



EVENT=$(echo "$INPUT" | jq -r '.hook_event_name')


case "$EVENT" in
  Notification)
    TITLE=$(echo "$INPUT" | jq -r '.title // "Claude Code"')
    MESSAGE=$(echo "$INPUT" | jq -r '.message // "Needs your attention"')
    TYPE=$(echo "$INPUT" | jq -r '.notification_type // "unknown"')

    case "$TYPE" in
      permission_prompt)
        URGENCY="critical"
        ;;
      *)
        URGENCY="normal"
        ;;
    esac

    dunstify -a "Claude Code" -u "$URGENCY" -i terminal "$TITLE" "$MESSAGE"
    ;;

  Stop)
    STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active')
    if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
      exit 0
    fi

    dunstify -a "Claude Code" -u "low" -i terminal "Task Complete" "Claude has finished responding"
    ;;
esac

exit 0
