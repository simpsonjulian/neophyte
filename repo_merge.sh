#!/bin/bash
set -x

die() {
  echo $1;exit 1
}

destination=$1
[ -n "$destination" ] || die "Usage: $0 /path/to/new/repo <github user> <list of repos> <list of branches> <new repo>"

GITHUB_USER=$2
[ -n "$GITHUB_USER" ] || GITHUB_USER='neo4j'
echo "GITHUB_USER: $GITHUB_USER"

PROJECTS=$3
[ -n "$PROJECTS" ] || PROJECTS="community advanced enterprise manual packaging python-embedded cypher-plugin gremlin-plugin parents testing-utils"
echo "PROJECTS: $PROJECTS"

BRANCHES=$4
[ -n "$BRANCHES" ] || BRANCHES="1.5-maint 1.6-maint 1.7-maint 1.8-maint"
echo "BRANCHES: $BRANCHES"

REPOSITORY=$5
[ -n "$REPOSITORY" ] || REPOSITORY="neo4j"
echo "REPOSITORY: $REPOSITORY"

in_repo() {
  local command=$1
  ( cd $destination && eval $command )
}

merge_branch() {
  local project=$1
  local branch=$2
  in_repo "git merge -s ours --no-commit ${project}/${branch}"
  in_repo "git read-tree --prefix=${project}/ -u ${project}/${branch}"
  in_repo "git commit -m 'Subtree merged in ${project}'"
}

# Step 0: make a repo to populate
[ ! -d "$destination" ] || die "Oops, it's already there"
mkdir -p $destination
( cd $destination && git init )

# Step 1: make a README and master branch
echo "Replace me with beautiful readme " > $destination/README
in_repo "git add README ;git commit -m 'First commit' README"

# Step 2: make remotes for all the projects
for project in $PROJECTS; do
  in_repo "git remote add -f ${project} git://github.com/${GITHUB_USER}/${project}.git"
done

# Step 3: make all the branches that we need
for branch in $BRANCHES; do
  in_repo "git branch $branch"
  in_repo "git checkout $branch"
done

# Step 4: merge all the things!
for branch in $BRANCHES; do
  in_repo "git checkout $branch"
  for project in $PROJECTS; do
    merge_branch $project $branch
    echo "Going to merge $branch on $project"
  done
done
in_repo "git checkout master"
for project in $PROJECTS; do
  merge_branch $project master
done

# Step 5: push to Github
in_repo "git remote add origin git@github.com:$GITHUB_USER/$REPOSITORY.git"
in_repo "git push origin master"
for branch in $BRANCHES; do
  in_repo "git push origin $branch"
done
