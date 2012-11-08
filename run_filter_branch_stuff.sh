#!/bin/bash
set -e
set -x

directory=$1

cd $directory
git reset --hard

pattern="^\.$|^\.\.$|^\.\/$directory$|^\.\/\.[a-z]"
pattern="'$pattern'"

git filter-branch -f --tree-filter "mkdir -p $directory && find . -maxdepth 1 | egrep -v $pattern | while read object; do git mv -f \$object $directory/.; done || true" HEAD
