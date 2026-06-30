#!/bin/bash
set -euo pipefail

# Configure the runner using environment variables passed to the container
: "${GH_OWNER:?GH_OWNER must be set}"
: "${GH_REPO:?GH_REPO must be set}"
: "${GH_TOKEN:?GH_TOKEN must be set}"
: "${GH_PAT:?GH_PAT must be set}"

./config.sh --url "https://github.com/${GH_OWNER}/${GH_REPO}" \
  --token "${GH_TOKEN}" \
  --name "internal-jenkins-bridge" \
  --labels "jenkins-trigger" \
  --unattended \
  --replace

# Handle graceful shutdown on container stop
cleanup() {
  echo "Removing runner..."

  remove_token="$({
    curl -fsSL -X POST \
      -H "Authorization: token ${GH_PAT}" \
      -H "Accept: application/vnd.github+json" \
      "https://api.github.com/repos/${GH_OWNER}/${GH_REPO}/actions/runners/remove-token" \
    | jq -r '.token'
  } 2>/dev/null || true)"

  if [ -n "${remove_token}" ] && [ "${remove_token}" != "null" ]; then
    ./config.sh remove --token "${remove_token}" || true
  else
    echo "Could not obtain runner removal token; leaving registration behind."
  fi
}
trap cleanup INT TERM

./run.sh &
wait "$!"
