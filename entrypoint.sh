#!/bin/bash
# entrypoint.sh

# Configure the runner using environment variables passed to the container
./config.sh --url https://github.com/${GH_OWNER}/${GH_REPO} \
  --token ${GH_TOKEN} \
  --name "internal-jenkins-bridge" \
  --labels "jenkins-trigger" \
  --unattended \
  --replace

# Handle graceful shutdown on container stop
cleanup() {
  echo "Removing runner..."
  ./config.sh remove --token ${GH_TOKEN}
}
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh &
wait $!
