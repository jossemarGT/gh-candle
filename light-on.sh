#!/bin/sh

set -e

GH_USER=''
TARGET_DIR="."
TARGET_BRANCH=''
DRY_RUN=''
: "${TMP_DIR:=}"
: "${DEBUG:=}"

# A year ago BSD date
# date -v '-1y'  '+%Y-%m-%dT00:00:00.000+00:00'
#
# A year ago GNU date
# date '+%Y-%m-%dT00:00:00.000+00:00' -d'1 year ago'
#
# TODO: Consider GNU/BSD x-compatibility
# it could be done by looking up 'GNU coreutils' string within the binary
# strings $(command -v date) | grep -q 'GNU coreutils'
#
: "${DATE_START:=$(date '+%Y-%m-%dT00:00:00.000+00:00' -d'1 year ago')}"
: "${DATE_END:=}"

usage() {
  echo "usage: $0 [-b <git branch>] [-g <git path>] [-d] [-h] <GitHub handle>
  -g    set local git repository for activity shadowing. Default: '$TARGET_DIR'
  -b    set local git branch for activity shadowing. Default: 'shadow/<GitHub handle>'
  -d    dry-run
  -h    show help

environment variables overrides:
  GH_TOKEN   - GH Personal access token, used for GH API lookups. Default: <empty>
  DATE_START - GH graph to be synced start date. Default: ${DATE_START}
  DATE_END   - GH graph to be synced end date, uses \"today\" when empty. Default: <empty>
  DEBUG      - When set, prints out debug messages

examples:
  GH_TOKEN='xxxxxx' $0 octocat"
}

debug() {
  [ -z "${DEBUG}" ] || echo '[DEBUG] ' "$@" >&2
}

warn() {
  echo '[WARN] ' "$@" >&2
}

fatal() {
  echo '[ERROR] ' "$@" >&2
  exit 1
}

check_dependencies() {
  for dep in 'gh' 'git'; do
    if ! command -v "${dep}" >/dev/null 2>&1; then
      fatal "${dep} not found. Please install it and try again"
    fi
  done
}

check_git_target() {
  GIT_DIR="$(realpath "${TARGET_DIR}")/.git"

  if [ -d "${GIT_DIR}" ]; then
    GIT_DIR="${GIT_DIR}" git rev-parse --git-dir >/dev/null 2>&1 || fatal "${TARGET_DIR} is not a valid git repository"
  else
    fatal "${TARGET_DIR} is not a git repository"
  fi
}

setup_tmp() {
  TMP_DIR=$(mktemp -d -t sync-contrib-graph.XXXXXXXXXX)
  debug "workspace ${TMP_DIR}"

  cleanup() {
    code=$?
    set +e
    trap - EXIT
    rm -rf "${TMP_DIR}"
    exit $code
  }
  trap cleanup INT EXIT

  export TMP_DIR
}

query_github() {
  _RESPOSE_FILE="${1}"

  # https://docs.github.com/en/graphql/overview/explorer
  cat >"${TMP_DIR}/query.graphql" <<EOF
{
  user(login: "${GH_USER}") {
    name
    contributionsCollection(
      from: "${DATE_START}"
      to: "${DATE_END}"
    ) {
      contributionCalendar {
        weeks {
          contributionDays {
            contributionCount
            date
          }
        }
      }
    }
  }
}
EOF

  if [ -z "${DATE_END}" ]; then
    sed -i '/to:/d' "${TMP_DIR}/query.graphql"
  fi

  GRAPHQL_QUERY="$(cat "${TMP_DIR}/query.graphql")"
  JQ_QUERY='.data.user.contributionsCollection.contributionCalendar.weeks[].contributionDays[]
            | select(.contributionCount > 0)
            | "\(.date) \(.contributionCount)"'

  debug "graphql query\n${GRAPHQL_QUERY}"
  debug "jq query\n${JQ_QUERY}"
  GH_PAGER='cat' gh api graphql --paginate -f "query=${GRAPHQL_QUERY}" --jq "${JQ_QUERY}" >"${_RESPOSE_FILE}"
}

generate_shadow_activity() {
  COORDINATES_FILE=${1}

  $DRY_RUN cd "${TARGET_DIR}"
  $DRY_RUN git checkout -b "${TARGET_BRANCH}"

  while read -r COORDINATE; do
    DATE="${COORDINATE% *}"
    COUNT="${COORDINATE#* }"

    [ -z "${COUNT}" ] && continue

    for i in $(seq 1 "${COUNT}"); do
      # https://git-scm.com/book/en/v2/Git-Internals-Environment-Variables#_committing
      $DRY_RUN export GIT_AUTHOR_DATE="${DATE}T00:00:00"
      $DRY_RUN export GIT_COMMITER_DATE="${DATE}T00:00:00"
      $DRY_RUN git commit --allow-empty -m "Shadow ${i}/${COUNT} activities from ${GH_USER}"
    done
  done <"${COORDINATES_FILE}"

  unset GIT_AUTHOR_DATE GIT_COMMITER_DATE
}

main() {
  check_dependencies
  check_git_target

  [ -n "$TMP_DIR" ] || setup_tmp

  query_github "${TMP_DIR}/response.txt"

  generate_shadow_activity "${TMP_DIR}/response.txt"
}

while getopts 'b:dg:h' c; do
  case "${c}" in
  b)
    TARGET_BRANCH="${OPTARG}"
    ;;
  d)
    DRY_RUN="echo"
    ;;
  g)
    TARGET_DIR="${OPTARG}"
    ;;
  h)
    usage
    exit 0
    ;;
  *)
    usage
    exit 1
    ;;
  esac
done

# check args
shift $((OPTIND - 1))
GH_USER="${1}"

if [ -z "${GH_USER}" ]; then
  usage
  exit 1
fi

if [ -z "${GH_TOKEN}" ]; then
  fatal "GH_TOKEN environment variable is missing"
fi

if [ -z "${TARGET_BRANCH}" ]; then
  TARGET_BRANCH="shadow/${GH_USER}"
fi

main
