#!/bin/bash

set -e
set -o xtrace

REPO=github.com/${OWNER:?user or organization for repo not set}/${PROJECT:?}

echo "Glidebot $GOPATH/src/$REPO"

GLIDEBOT_USER=`git config github.user`

go get -d $REPO
cd $GOPATH/src/$REPO

if [[ $(git diff --shortstat 2> /dev/null | tail -n1) != "" ]]; then
  echo "$GOPATH/src/$REPO was already dirty, aborting"
  exit 1
fi

git checkout master
git pull
git checkout -b glidebot-`date +"%s"`

glide up

# if dirty, commit, push branch
if [[ $(git diff --shortstat 2> /dev/null | tail -n1) != "" ]]; then
  echo "Update made folder dirty, creating PR"
  git add glide.lock vendor
  git commit -a -m "Update glide dependencies"
  hub fork
  git push -u glidebot
  hub pull-request -m "Update glide dependencies" -b ${OWNER:?}:master

  # TODO perhaps it would be neat to close any existing
  # glidebot PR?
else
  echo "Not dirty, nothing to do"
fi

git checkout master
