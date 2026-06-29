#!/bin/bash
set -euo pipefail

# Configure the runner using environment variables passed to the container
: "${GH_OWNER:?GH_OWNER must be set}"
: "${GH_REPO:?GH_REPO must be set}"
: "${GH_TOKEN:?GH_TOKEN must be set}"

./config.sh --url "https://github.com/${GH_OWNER}/${GH_REPO}" \
  --token "${GH_TOKEN}" \
  --name "internal-jenkins-bridge" \
  --labels "jenkins-trigger" \
  --unattended \
  --replace

# Handle graceful shutdown on container stop
cleanup() {
  echo "Removing runner..."
  ./config.sh remove --token "${GH_TOKEN}" || true
}
trap cleanup INT TERM

./run.sh &
wait "$!"
