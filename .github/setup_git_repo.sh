#!/bin/bash

RESET_BRANCH="${RESET_BRANCH:-master}"
# Update user fork
rm -rf /root/repo || true
git clone $FORK_REPO /root/repo
cp ../scripts/create_pr.sh /create_pr.sh

pushd /root/repo
git remote add upstream $UPSTREAM_REPO
git fetch --all
git reset --hard upstream/${RESET_BRANCH}
git push -fv
git branch -D $WORK_BRANCH || true
git checkout -b $WORK_BRANCH
git reset --hard upstream/${RESET_BRANCH}
git push -fv -u origin $WORK_BRANCH
popd

