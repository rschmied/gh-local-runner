#!/bin/bash
set -euo pipefail

# Instead of registering the runner repository-by-repository, it is highly
# recommended to register it at the GitHub Organization level so all your
# migrated repositories can share it.
#
# Go to your GitHub Org -> Settings -> Actions -> Runners -> New runner.
#
# Copy the temporary registration token provided in the UI.

: "${GH_OWNER:?GH_OWNER must be set}"
: "${GH_REPO:?GH_REPO must be set}"
: "${GH_TOKEN:?GH_TOKEN must be set}"

# docker build -t github-runner .

docker run -d --name gh-runner \
  --add-host=host.docker.internal:host-gateway \
  -e GH_OWNER="${GH_OWNER}" \
  -e GH_REPO="${GH_REPO}" \
  -e GH_TOKEN="${GH_TOKEN}" \
  github-runner
