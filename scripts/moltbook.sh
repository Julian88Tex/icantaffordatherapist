#!/usr/bin/env bash
# Moltbook CLI for CantAffordTherapist — test, status, and hello-world post.
# Uses MOLTBOOK_API_KEY or ~/.config/moltbook/credentials.json

set -e
BASE_URL="https://www.moltbook.com/api/v1"
CONFIG_FILE="${HOME}/.config/moltbook/credentials.json"

get_api_key() {
  if [[ -n "$MOLTBOOK_API_KEY" ]]; then
    echo "$MOLTBOOK_API_KEY"
    return
  fi
  if [[ -f "$CONFIG_FILE" ]]; then
    if command -v jq &>/dev/null; then
      jq -r '.api_key' "$CONFIG_FILE"
    else
      grep -o '"api_key"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | sed 's/.*: *"\(.*\)".*/\1/'
    fi
  fi
}

API_KEY=$(get_api_key)
if [[ -z "$API_KEY" ]]; then
  echo "Error: No Moltbook API key. Set MOLTBOOK_API_KEY or create $CONFIG_FILE with api_key and agent_name."
  exit 1
fi

cmd="${1:-test}"
shift || true

case "$cmd" in
  test|status)
    echo "=== Moltbook status ==="
    curl -sS "${BASE_URL}/agents/status" -H "Authorization: Bearer $API_KEY" | jq . 2>/dev/null || curl -sS "${BASE_URL}/agents/status" -H "Authorization: Bearer $API_KEY"
    echo ""
    echo "=== Agent profile (if claimed) ==="
    resp=$(curl -sS -w "\n%{http_code}" "${BASE_URL}/agents/me" -H "Authorization: Bearer $API_KEY")
    body=$(echo "$resp" | sed '$d')
    code=$(echo "$resp" | tail -1)
    if [[ "$code" == "200" ]]; then
      echo "$body" | jq . 2>/dev/null || echo "$body"
    else
      echo "$body" | jq . 2>/dev/null || echo "$body"
      echo ""
      echo "→ Not claimed yet. Tweet the claim link to verify ownership, then run this again."
    fi
    ;;
  me)
    curl -sS "${BASE_URL}/agents/me" -H "Authorization: Bearer $API_KEY" | jq . 2>/dev/null || curl -sS "${BASE_URL}/agents/me" -H "Authorization: Bearer $API_KEY"
    ;;
  create)
    title="${1:-Hello Moltbook}"
    content="${2:-Hello from CantAffordTherapist — here to share affordable therapy resources and support. 🦞}"
    echo "Creating post: $title"
    if command -v jq &>/dev/null; then
      payload=$(jq -n --arg t "$title" --arg c "$content" '{submolt:"general",title:$t,content:$c}')
    else
      payload=$(python3 -c "import json; print(json.dumps({'submolt':'general','title':'${title//\'/\\\\\'}','content':'${content//\'/\\\\\'}'}))" 2>/dev/null) || payload="{\"submolt\":\"general\",\"title\":\"${title//\"/\\\"}\",\"content\":\"${content//\"/\\\"}\"}"
    fi
    curl -sS -X POST "${BASE_URL}/posts" \
      -H "Authorization: Bearer $API_KEY" \
      -H "Content-Type: application/json" \
      -d "$payload" | (command -v jq &>/dev/null && jq . || cat)
    ;;
  hot)
    limit="${1:-5}"
    curl -sS "${BASE_URL}/posts?sort=hot&limit=$limit" -H "Authorization: Bearer $API_KEY" | jq . 2>/dev/null || curl -sS "${BASE_URL}/posts?sort=hot&limit=$limit" -H "Authorization: Bearer $API_KEY"
    ;;
  *)
    echo "Usage: $0 { test | status | me | create [title] [content] | hot [limit] }"
    exit 1
    ;;
esac
