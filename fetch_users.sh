#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage: ${0##*/} [-t TOKEN] [options]

Options:
  -t, --token TOKEN           Social WiFi API token. Can also be set with SOCIALWIFI_TOKEN.
  -v, --venue-id ID           Venue identifier (UUID). Can also be set with SOCIALWIFI_VENUE_ID. (default: c713c145-79c7-46f5-ac8d-b4ff8b17d046)
  -b, --base-url URL          Base URL for the API (default: https://api.socialwifi.com).
  -s, --page-size NUMBER      Page size for paginated requests (default: 100).
  -S, --sort FIELD            Sort parameter (default: -last_visit_on).
  -o, --output FILE           Save JSON output to FILE instead of stdout.
  -f, --filter QUERY          Extra query string appended to the query (e.g. "filter[project]=UUID").
  -A, --auth-scheme SCHEME    Authorization scheme (default: Bearer). Example values: Bearer, Token.
  -h, --help                  Show this help message.

Examples:
  SOCIALWIFI_TOKEN="token" ./fetch_users.sh
  ./fetch_users.sh -t token -s 50 -S last_visit_on -f "filter[project]=uuid" -o usuarios.json
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
VENUE_ID=${SOCIALWIFI_VENUE_ID:-"c713c145-79c7-46f5-ac8d-b4ff8b17d046"}
BASE_URL=${SOCIALWIFI_BASE_URL:-"https://api.socialwifi.com"}
PAGE_SIZE=${SOCIALWIFI_PAGE_SIZE:-100}
SORT=${SOCIALWIFI_SORT:-"-last_visit_on"}
OUTPUT=${SOCIALWIFI_OUTPUT:-}
FILTER=${SOCIALWIFI_FILTER:-}
AUTH_SCHEME=${SOCIALWIFI_AUTH_SCHEME:-Bearer}

while (($#)); do
  case "$1" in
    -t|--token)
      TOKEN=$2
      shift 2
      ;;
    -v|--venue-id)
      VENUE_ID=$2
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
    -A|--auth-scheme)
      AUTH_SCHEME=$2
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

if [[ -z "$VENUE_ID" ]]; then
  echo "Error: venue id is required." >&2
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

next_url="${BASE_URL%/}/users/user-data/?filter[venue]=${VENUE_ID}&page[number]=1&page[size]=$PAGE_SIZE"

if [[ -n "$SORT" ]]; then
  next_url+="&sort=$SORT"
fi

if [[ -n "$SANITIZED_FILTER" ]]; then
  next_url+="&$SANITIZED_FILTER"
fi

all_results='[]'

while [[ -n "$next_url" ]]; do
  if ! response=$(curl -fsSL \
    -H "Authorization: $AUTH_SCHEME $TOKEN" \
    -H "Accept: application/vnd.api+json" \
    "$next_url"); then
    echo "Error: request failed for $next_url" >&2
    exit 1
  fi

  page_results=$(printf '%s' "$response" | jq -c '(.data // [])')
  all_results=$(jq -s 'add' <(printf '%s' "$all_results") <(printf '%s' "$page_results"))

  next_url=$(printf '%s' "$response" | jq -r '(.links.next // .next // "")')

  if [[ -n "$next_url" && "$next_url" != http* ]]; then
    next_url="${BASE_URL%/}$next_url"
  fi

  if [[ -z "$next_url" || "$next_url" == "null" ]]; then
    next_url=''
  fi

  sleep 0.2
done

if [[ -n "$OUTPUT" ]]; then
  printf '%s\n' "$all_results" | jq '.' > "$OUTPUT"
  echo "Saved $(jq 'length' "$OUTPUT") records to $OUTPUT" >&2
else
  printf '%s\n' "$all_results" | jq '.'
fi
