#!/bin/sh -x
# hack: Merge the latest changes from the master branch into your current branch
ref=$(git symbolic-ref HEAD 2&gt; /dev/null) || exit 0
CURRENT="${ref#refs/heads/}"
git checkout master
git pull origin master
git checkout ${CURRENT}
git rebase master
