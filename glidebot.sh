#!/bin/bash

set -e

# TODO make configurable
USER=raboof
PROJECT=connbeat
REPO=github.com/$USER/$PROJECT

GLIDEBOT_USER=`git config github.user`

go get $REPO
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
  git remote add glidebot git@github.com:$GLIDEBOT_USER/$PROJECT 2>/dev/null || true
  git add glide.lock vendor
  git commit -a -m "Update glide dependencies"
  git push -u glidebot
  # TODO probably needs to make base branch explicit
  # when not using the same user for $USER and $GLIDEBOT_USER
  hub pr -m "Update glide dependencies"

  # TODO perhaps it would be neat to close any existing
  # glidebot PR?
else
  echo "Not dirty, nothing to do"
fi

git checkout master
