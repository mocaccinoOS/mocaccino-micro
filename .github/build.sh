#!/bin/bash
set -x
# CONFIGURE: Tweak to suit your needs
# You might want to remove $PULL_REPOSITORY if you don't need to pull for any image

FINAL_REPO=$(echo "$FINAL_REPO" | tr '[:upper:]' '[:lower:]')
PULL_ARGS=
if [ -n "$PULL_REPOSITORY" ]; then
  PULL_ARGS="--pull-repository $PULL_REPOSITORY"
fi

if [ "$PUSH_CACHE" == "true" ]; then
  sudo -E luet build $PULL_ARGS \
          --only-target-package \
          --pull --push --image-repository $FINAL_REPO \
          --from-repositories --no-spinner --live-output --tree packages "$1"
else
  sudo -E luet build $PULL_ARGS \
          --only-target-package \
          --pull --image-repository $FINAL_REPO \
          --from-repositories --no-spinner --live-output --tree packages "$1"
fi