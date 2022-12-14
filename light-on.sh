#!/bin/sh

set -e

GH_USER=
: "${TARGET_DIR=.}"
: "${TARGET_BRANCH:=}"
: "${DRY_RUN:=}"
: "${TMP_DIR:=}"
: "${DEBUG:=}"
: "${DATE_END:=}"
: "${SKIP_GIT_INIT:=}"

if strings "$(command -v date)" | grep -q 'GNU coreutils'; then
  : "${DATE_START:=$(date '+%Y-%m-%dT00:00:00.000+00:00' -d'1 year ago')}"
else
  : "${DATE_START:=$(date -v '-1y' '+%Y-%m-%dT00:00:00.000+00:00')}"
fi

usage() {
  echo "usage: $0 [-b <git branch>] [-g <git path>] [-d] [-h] <GitHub handle>
  -g    set local git repository for activity shadowing. Default: '$TARGET_DIR'
  -b    set local git branch for activity shadowing. Default: 'shadow/<GitHub handle>'
  -k    skip initializing git repository
  -d    dry-run
  -h    show help

environment variables overrides:
  GH_TOKEN   - GH Personal access token used for GH API lookups. Fails when empty.
  DATE_START - GH graph to be synced start date. Uses \"a year ago\" when empty.
  DATE_END   - GH graph to be synced end date. Uses \"today\" when empty.
  DEBUG      - When set, prints out debug messages

examples:
  GH_TOKEN='xxxxxx' $0 octocat"
}

next_steps() {
  _MAIN_BRANCH=$(git config --global --get init.defaultBranch || echo '<main branch>')

  echo "

    )
   (_)
  .-'-.   Local shadow generation succeded! Please proceed with the following steps to update GH graph:
  |   |
  |   |     * cd ${TARGET_DIR}
  |   |     * git checkout ${_MAIN_BRANCH}
  |   |     * git merge ${TARGET_BRANCH}
  |   |     * git push origin ${_MAIN_BRANCH}
  |   |
  \`---'
"
}

debug() {
  [ -z "${DEBUG}" ] || echo '[DEBUG] ' "$@" >&2
}

warn() {
  echo '[WARN] ' "$@" >&2
}

error() {
  echo '[ERROR] ' "$@" >&2
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

initialize_git_target() {
  _DIR="${1}"

  if [ ! -d "${_DIR}" ]; then
    warn "${_DIR} will be created"
    $DRY_RUN mkdir -p "${_DIR}"
  fi

  $DRY_RUN cd "${_DIR}"
  $DRY_RUN git init
  $DRY_RUN git commit --allow-empty -m "Initial commit"
  $DRY_RUN cd -
}

check_git_target() {
  GIT_DIR="${TARGET_DIR}/.git"

  if [ -d "${GIT_DIR}" ]; then
    GIT_DIR="${GIT_DIR}" git rev-parse --git-dir >/dev/null 2>&1 || fatal "${TARGET_DIR} is not a valid git repository"
  else
    [ -z "${SKIP_GIT_INIT}" ] || fatal "${TARGET_DIR} is not a git repository"
    initialize_git_target "${TARGET_DIR}"
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
    sed -i -e '/to:/d' "${TMP_DIR}/query.graphql"
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

  next_steps
}

while getopts 'b:dg:hk' c; do
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
  k)
    SKIP_GIT_INIT='y'
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
  error "Missing <GitHub handle> argument"
  exit 1
fi

if [ -z "${GH_TOKEN}" ]; then
  fatal "GH_TOKEN environment variable is missing"
fi

if [ -z "${TARGET_BRANCH}" ]; then
  TARGET_BRANCH="shadow/${GH_USER}"
fi

main
