#!/bin/bash
set -x
die() {
  echo $1
  exit 1
}
[ "$#" == 1 ] || die "I need a component name"
component=$1

git filter-branch -f --tree-filter \
"mkdir -p ${component} && find . -maxdepth 1 | egrep -v '^\.$|^\.git$|^\.\/${component}$' | while read o;\
do \
  git mv -f \${o} ${component};\
done" HEAD
