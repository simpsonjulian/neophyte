#!/bin/bash
merge_branch() {
  local project=$1
  local branch=$2
  git remote add -f ${project} git://github.com/neo4j/${project}.git
  git merge -s ours --no-commit ${project}/${branch}
  git read-tree --prefix=${project}/ -u ${project}/${branch}
  git commit -m "Subtree merged in ${project}"
}
for project in community advanced enterprise manual packaging; do 
  for branch in 1.4-maint 1.5-maint 1.6-maint 1.7-maint 1.8-maint; do
    merge_branch $project $branch
  done
done
