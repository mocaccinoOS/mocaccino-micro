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
# e.g. packages/acct-group/amavis/0/
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
    
    # Strategy can be: release, tags or "refs"
    # Refs parses thru git tags
    AUTOBUMP_STRATEGY=$(yq r $PACKAGE_PATH/definition.yaml 'labels."autobump.strategy"')
    
    # Prefix to trim from the version
    TRIM_PREFIX=$(yq r $PACKAGE_PATH/definition.yaml 'labels."autobump.trim_prefix"')

    # A json map of replace rules
    STRING_REPLACE=$(yq r $PACKAGE_PATH/definition.yaml 'labels."autobump.string_replace"')

    # You can specify a string match that should be contained in the versions
    # to be considered. Valid for "refs" and tagging strategy
    VERSION_CONTAINS=$(yq r $PACKAGE_PATH/definition.yaml 'labels."autobump.version_contains"')

    if [[ "$AUTOBUMP_STRATEGY" == "release" ]]; then
        LATEST_TAG=$(curl https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/releases/latest -s | jq .tag_name -r)
    elif [[ "$AUTOBUMP_STRATEGY" == "refs" ]]; then
        LATEST_TAG=$(curl https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/git/refs/tags -s | jq '.[].ref | sub("refs\/tags\/"; "") | select(. | test("'$VERSION_CONTAINS'"))' -r | tail -n1 )
    else
        LATEST_TAG=$(curl https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/tags -s | jq -r '.[].name | select(. | test("'$VERSION_CONTAINS'"))' -r | head -1 )
    fi

    LATEST_TAG=${LATEST_TAG#v} # semver
    LATEST_TAG=${LATEST_TAG#$TRIM_PREFIX} # go..

    for i in $(echo "$STRING_REPLACE" | jq -r 'keys[]'); do
        WITH=$(echo "$STRING_REPLACE" | jq -r '."'$i'"')
        echo "Replacing $i with '$WITH'"
        LATEST_TAG=$(echo "$LATEST_TAG" | sed -r 's/'$i'+/'$WITH'/g')
    done

    echo "Latest tag for $PACKAGE_NAME is $LATEST_TAG"

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

        # Update runtime version
        yq w -i $PACKAGE_PATH/definition.yaml version "$LATEST_TAG" --style double

        if [ "${AUTO_GIT}" == "true" ]; then
            git add $PACKAGE_PATH/
            git commit -m "Bump $PACKAGE_CATEGORY/$PACKAGE_NAME to $LATEST_TAG"
            git push -f -v origin $BRANCH_NAME

            # Branch is ready now to open PR
            hub pull-request $HUB_ARGS -m "$(git log -1 --pretty=%B)"

            git checkout $START_GIT_BRANCH # Return to original branch
        fi

    fi

    echo

done
