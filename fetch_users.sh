#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage: ${0##*/} [-t TOKEN] [-a ACCOUNT_ID] [options]

Options:
  -t, --token TOKEN           Social WiFi API token. Can also be set with SOCIALWIFI_TOKEN.
  -a, --account-id ID         Account identifier. Can also be set with SOCIALWIFI_ACCOUNT_ID.
  -b, --base-url URL          Base URL for the API (default: https://api.socialwifi.com).
  -f, --filter QUERY          Additional query string to filter users (e.g. "gender=female").
  -l, --limit NUMBER          Page size for paginated requests (default: 100).
  -o, --output FILE           Save JSON output to FILE instead of stdout.
  -h, --help                  Show this help message.

Examples:
  SOCIALWIFI_TOKEN=\"token\" SOCIALWIFI_ACCOUNT_ID=123 ./fetch_users.sh
  ./fetch_users.sh -t token -a 123 -f "email__icontains=gmail.com"
USAGE
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: '$1' is required but not installed" >&2
    exit 1
  fi
}

require_cmd curl
require_cmd jq

TOKEN=${SOCIALWIFI_TOKEN:-}
ACCOUNT_ID=${SOCIALWIFI_ACCOUNT_ID:-}
BASE_URL=${SOCIALWIFI_BASE_URL:-"https://api.socialwifi.com"}
FILTER=${SOCIALWIFI_FILTER:-}
LIMIT=${SOCIALWIFI_LIMIT:-100}
OUTPUT=${SOCIALWIFI_OUTPUT:-}

while (($#)); do
  case "$1" in
    -t|--token)
      TOKEN=$2
      shift 2
      ;;
    -a|--account-id)
      ACCOUNT_ID=$2
      shift 2
      ;;
    -b|--base-url)
      BASE_URL=$2
      shift 2
      ;;
    -f|--filter)
      FILTER=$2
      shift 2
      ;;
    -l|--limit)
      LIMIT=$2
      shift 2
      ;;
    -o|--output)
      OUTPUT=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -* )
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

if [[ -z "$TOKEN" ]]; then
  echo "Error: API token is required." >&2
  usage >&2
  exit 1
fi

if [[ -z "$ACCOUNT_ID" ]]; then
  echo "Error: account id is required." >&2
  usage >&2
  exit 1
fi

query_params="limit=$LIMIT"
if [[ -n "$FILTER" ]]; then
  # Strip leading question mark or ampersand if provided
  FILTER=${FILTER#\?}
  FILTER=${FILTER#\&}
  query_params+="&$FILTER"
fi

next_url="$BASE_URL/accounts/$ACCOUNT_ID/users/?$query_params"
all_results='[]'

while [[ -n "$next_url" ]]; do
  if ! response=$(curl -fsSL -H "Authorization: Token $TOKEN" -H "Accept: application/json" "$next_url"); then
    echo "Error: request failed for $next_url" >&2
    exit 1
  fi

  page_results=$(printf '%s' "$response" | jq '.results // []')
  all_results=$(jq -s 'add' <(printf '%s' "$all_results") <(printf '%s' "$page_results"))

  next_url=$(printf '%s' "$response" | jq -r '.next // empty')
  if [[ -n "$next_url" && "$next_url" != http* ]]; then
    next_url="$BASE_URL$next_url"
  fi

  sleep 0.2
done

if [[ -n "$OUTPUT" ]]; then
  printf '%s\n' "$all_results" | jq '.' > "$OUTPUT"
  echo "Saved $(jq 'length' "$OUTPUT") users to $OUTPUT" >&2
else
  printf '%s\n' "$all_results" | jq '.'
fi
