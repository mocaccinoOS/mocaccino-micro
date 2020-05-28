#!/bin/bash
#set -ex
# Auto bumper script by Ettore Di Giacinto <mudler@sabayonlinux.org>
# License: MIT
# Requires yq and jq
# It bumps to latest tag annotated in the specs

# Options
AUTO_GIT="${AUTO_GIT:-false}"

START_GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
HUB_ARGS="${HUB_ARGS:--b $START_GIT_BRANCH}"

# Fetch depedendencies if not available
PATH=$PATH:$ROOT_DIR/.bin
hash luet 2>/dev/null || {
    mkdir $ROOT_DIR/.bin/;
    wget https://github.com/mudler/luet/releases/download/0.7.4/luet-0.7.4-linux-amd64 -O $ROOT_DIR/.bin/luet
    chmod +x $ROOT_DIR/.bin/luet
}

hash jq 2>/dev/null || {
    mkdir $ROOT_DIR/.bin/;
    wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O $ROOT_DIR/.bin/jq
    chmod +x $ROOT_DIR/.bin/jq
}

hash yq 2>/dev/null || {
    mkdir $ROOT_DIR/.bin/;
    wget https://github.com/mikefarah/yq/releases/download/3.3.0/yq_linux_amd64 -O $ROOT_DIR/.bin/yq
    chmod +x $ROOT_DIR/.bin/yq
}

# Luet tree package list
PKG_LIST=$(luet tree pkglist --tree $ROOT_DIR/ -o json)

# For each package in the tree, get the path where the spec resides
# e.g. tree/sabayonlinux.org/acct-group/amavis/0/
for i in $(echo "$PKG_LIST" | jq -r '.packages[].path'); do

    PACKAGE_PATH=$i
    PACKAGE_NAME=$(echo "$PKG_LIST" | jq -r ".packages[] | select(.path==\"$i\").name")
    PACKAGE_CATEGORY=$(echo "$PKG_LIST" | jq -r ".packages[] | select(.path==\"$i\").category")
    PACKAGE_VERSION=$(echo "$PKG_LIST" | jq -r ".packages[] | select(.path==\"$i\").version")
    STRIPPED_PACKAGE_VERSION=${PACKAGE_VERSION%\+*}
    VERSION=$STRIPPED_PACKAGE_VERSION

    # Best effort: get original package name from labels
    GITHUB_REPO=$(yq r $PACKAGE_PATH/definition.yaml 'labels."github.repo"')
    GITHUB_OWNER=$(yq r $PACKAGE_PATH/definition.yaml 'labels."github.owner"')
    #LATEST_RELEASE=$(curl https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/releases/latest -s | jq .tag_name -r)
    LATEST_TAG=$(curl https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/tags -s | jq '.[0].name' -r)
    LATEST_TAG=${LATEST_TAG#v}

    [[ "$LATEST_TAG" == "null" ]] && LATEST_TAG=
    # versions are mismatching. Bump the version
    if [ -n "$LATEST_TAG" ] && [ $LATEST_TAG != "$STRIPPED_PACKAGE_VERSION" ] ; then
        echo "Bumping spec version of $PACKAGE_CATEGORY/$PACKAGE_NAME to $LATEST_TAG"

        BRANCH_NAME="bump_${PACKAGE_NAME}_${PACKAGE_CATEGORY}"
        if [ "${AUTO_GIT}" == "true" ]; then
            git branch -D $BRANCH_NAME
            git checkout -b $BRANCH_NAME
        fi

        # Generate new folder after the new version
        # e.g. tree/package/1.1 to tree/package/1.2
        package_dir=$(dirname $PACKAGE_PATH)
        new_version=$package_dir/$LATEST_TAG
        # Copy content from previous version
        cp -rfv $PACKAGE_PATH $new_version

        # Update runtime version
        yq w -i $new_version/definition.yaml version "$LATEST_TAG" --style double

        if [ "${AUTO_GIT}" == "true" ]; then
            git add $new_version/
            git rm -r $PACKAGE_PATH
            git commit -m "Bump $PACKAGE_CATEGORY/$PACKAGE_NAME to $LATEST_TAG"
            git push -f -v origin $BRANCH_NAME

            # Branch is ready now to open PR
            hub pull-request $HUB_ARGS -m "$(git log -1 --pretty=%B)"

            git checkout $START_GIT_BRANCH # Return to original branch
        fi

    fi

    echo

done
