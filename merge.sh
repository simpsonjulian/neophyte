#!/bin/bash

merge_branch() {
  local project=$1
  local branch=$2
  git remote add -f ${project} git://github.com/neo4j/${project}.git

  # this is the strategy for bringing in the master, not sure it actually works for branches.
  git merge -s ours --no-commit ${project}/${branch}
  git read-tree --prefix=${project}/ -u ${project}/${branch}
  git commit -m "Subtree merged in ${project}"
}

# Step 1: merge the master
#for project in community advanced enterprise manual packaging; do 
#  merge_branch $project master
#done

# Step 2: make release branches
for branch in 1.5-maint 1.6-maint 1.7-maint 1.8-maint; do 
  git branch $branch
  git push origin $branch
  git checkout $branch
  ./update.sh  $branch
done
