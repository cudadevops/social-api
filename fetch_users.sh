#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage: ${0##*/} [-t TOKEN] [-p PROJECT_ID] [options]

Options:
  -t, --token TOKEN           Social WiFi API token. Can also be set with SOCIALWIFI_TOKEN.
  -p, --project-id ID         Project identifier. Can also be set with SOCIALWIFI_PROJECT_ID.
  -b, --base-url URL          Base URL for the API (default: https://api.socialwifi.com).
  -s, --page-size NUMBER      Page size for paginated requests (default: 100).
  -S, --sort FIELD            Sort parameter (default: -last_visit_on).
  -o, --output FILE           Save JSON output to FILE instead of stdout.
  -f, --filter QUERY          Extra query string (e.g. "filter[last_visit_on][gte]=2023-01-01").
  -h, --help                  Show this help message.

Examples:
  SOCIALWIFI_TOKEN="token" SOCIALWIFI_PROJECT_ID=456 ./fetch_users.sh
  ./fetch_users.sh -t token -p 456 -s 50 -S -created -o usuarios.json
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
PROJECT_ID=${SOCIALWIFI_PROJECT_ID:-}
BASE_URL=${SOCIALWIFI_BASE_URL:-"https://api.socialwifi.com"}
PAGE_SIZE=${SOCIALWIFI_PAGE_SIZE:-100}
SORT=${SOCIALWIFI_SORT:--last_visit_on}
OUTPUT=${SOCIALWIFI_OUTPUT:-}
FILTER=${SOCIALWIFI_FILTER:-}

while (($#)); do
  case "$1" in
    -t|--token)
      TOKEN=$2
      shift 2
      ;;
    -p|--project-id)
      PROJECT_ID=$2
      shift 2
      ;;
    -b|--base-url)
      BASE_URL=$2
      shift 2
      ;;
    -s|--page-size)
      PAGE_SIZE=$2
      shift 2
      ;;
    -S|--sort)
      SORT=$2
      shift 2
      ;;
    -o|--output)
      OUTPUT=$2
      shift 2
      ;;
    -f|--filter)
      FILTER=$2
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

if [[ -z "$PROJECT_ID" ]]; then
  echo "Error: project id is required." >&2
  usage >&2
  exit 1
fi

if ! [[ $PAGE_SIZE =~ ^[0-9]+$ && $PAGE_SIZE -gt 0 ]]; then
  echo "Error: page size must be a positive integer." >&2
  exit 1
fi

SANITIZED_FILTER=$FILTER
while [[ -n "$SANITIZED_FILTER" && ( ${SANITIZED_FILTER:0:1} == '?' || ${SANITIZED_FILTER:0:1} == '&' ) ]]; do
  SANITIZED_FILTER=${SANITIZED_FILTER:1}
done

page_number=1
all_results='[]'

while :; do
  query="${BASE_URL%/}/users/project-user-data/?filter[project]=$PROJECT_ID&page[number]=$page_number&page[size]=$PAGE_SIZE&sort=$SORT"

  if [[ -n "$SANITIZED_FILTER" ]]; then
    query+="&$SANITIZED_FILTER"
  fi

  if ! response=$(curl -fsSL \
    -H "Authorization: Bearer $TOKEN" \
    -H "Accept: application/vnd.api+json" \
    "$query"); then
    echo "Error: request failed for $query" >&2
    exit 1
  fi

  page_results=$(printf '%s' "$response" | jq '.data // []')
  result_count=$(printf '%s' "$page_results" | jq 'length')
  if (( result_count == 0 )); then
    break
  fi

  all_results=$(jq -s 'add' <(printf '%s' "$all_results") <(printf '%s' "$page_results"))

  page_number=$((page_number + 1))
  sleep 0.2

done

if [[ -n "$OUTPUT" ]]; then
  printf '%s\n' "$all_results" | jq '.' > "$OUTPUT"
  echo "Saved $(jq 'length' "$OUTPUT") records to $OUTPUT" >&2
else
  printf '%s\n' "$all_results" | jq '.'
fi
