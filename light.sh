#!/bin/sh

set -e

GH_USER=""

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
  echo "usage: $0 [-h] <GitHub username>
  -h    show help
env. var. overrides:
  GH_TOKEN  - GH Personal access token, used for GH API lookups. Default: <empty>
  DATE_START - GH graph to be synced start date. Default: ${DATE_START}
  DATE_END   - GH graph to be synced end date, uses \"today\" when empty. Default: <empty>
examples:
  GH_TOKEN='xxxxxx' $0 octocat"
}

setup_tmp() {
  TMP_DIR=$(mktemp -d -t sync-contrib-graph.XXXXXXXXXX)
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

main() {
  [ -n "$TMP_DIR" ] || setup_tmp

  # https://docs.github.com/en/graphql/overview/explorer
  cat > "${TMP_DIR}/query.graphql" << EOF
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
  
  JQ_QUERY='.data.user.contributionsCollection.contributionCalendar.weeks[].contributionDays[] 
            | select(.contributionCount > 0) 
            | "\(.date) \(.contributionCount)"'

  GRAPHQL_QUERY="$(cat "${TMP_DIR}/query.graphql")"

  export GH_PAGER='cat'
  gh api graphql --paginate -f "query=${GRAPHQL_QUERY}" --jq "${JQ_QUERY}" > "${TMP_DIR}/response.txt"

  while read -r COORDINATE; do
    DATE="${COORDINATE% *}"
    COUNT="${COORDINATE#* }"

    [ -z "${COUNT}" ] && continue

    for i in $(seq 1 "${COUNT}"); do 
      echo "GIT_AUTHOR_DATE=${DATE}T00:00:00 GIT_COMMITER_DATE=${DATE}T00:00:00
            git commit --allow-empty -m 'Sync ${i}/${COUNT} contributions from ${GH_USER}'"
    done
  done < "${TMP_DIR}/response.txt"
}

while getopts 'h' c; do
  case "${c}" in
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

if [ -z "${1}" ]; then
  usage
  exit 1
fi

if [ -z "${GH_TOKEN}" ]; then
  echo "GH_TOKEN environment variable is missing"
  exit 1
fi

GH_USER="${1}"

main
