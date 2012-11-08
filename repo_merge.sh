#!/bin/bash
set -x

die() {
  echo $1;exit 1
}

destination=$1
[ -n "$destination" ] || die "Usage: $0 /path/to/new/repo <github user> <list of repos> <list of branches> <new repo user> <new repo name>"

ORIGIN_USER=$2
[ -n "$ORIGIN_USER" ] || ORIGIN_USER='neo4j'
echo "ORIGIN_USER: $ORIGIN_USER"

PROJECTS=$3
#[ -n "$PROJECTS" ] || PROJECTS="community advanced enterprise manual packaging python-embedded cypher-plugin gremlin-plugin parents testing-utils"
[ -n "$PROJECTS" ] || PROJECTS="manual packaging"
echo "PROJECTS: $PROJECTS"

BRANCHES=$4
#[ -n "$BRANCHES" ] || BRANCHES="1.5-maint 1.6-maint 1.7-maint 1.8-maint"
[ -n "$BRANCHES" ] || BRANCHES="1.5-maint 1.6-maint"
echo "BRANCHES: $BRANCHES"

DESTINATION_USER=$5
[ -n "$DESTINATION_USER" ] || DESTINATION_USER="neo4j"
echo "DESTINATION_USER: $DESTINATION_USER"

REPOSITORY=$6
[ -n "$REPOSITORY" ] || REPOSITORY="neo4j"
echo "REPOSITORY: $REPOSITORY"

working_dir="/tmp/repomerge"
rm -rf $working_dir
mkdir -p $working_dir

# algorithm:
# clone all projects and branches
# foreach $branch
#     foreach $project
#         run filter-branch
#         pull or fetch into new repo






in_repo() {
  local directory=$1
  local command=$2
  ( cd "$working_dir/$directory" && $command )
}

in_working_dir() {
  local command=$1
  ( cd $working_dir && eval $command )
}

for project in $PROJECTS; do
  in_working_dir "git clone git://github.com/neo4j/$project"
  for branch in $BRANCHES; do
    pattern="^\.$|^\.\/\.git$|^\.\/${project}$"
    movecommand="mkdir -p $project && find . -maxdepth 1 | egrep -v $pattern | while read object; do git mv -f \$object $project .; done || true"
    command="git filter-branch -f --tree-filter '$movecommand' HEAD"
    in_repo $project "$command" 
    #in_repo $project "mkdir -p $project"
    #in_repo $project "find . -maxdepth 1 | egrep -v \"^\.$|^\.\/\.git$|^\.\/\${project}$\" | while read object; do echo \"\${object} ${project}\"; done"
  done
done





# old stuff
exit






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
in_repo "git add README ;git commit -m 'Repo merge initial commit' README"

# Step 2: make remotes for all the projects
for project in $PROJECTS; do
  in_repo "git remote add -f ${project} git://github.com/${ORIGIN_USER}/${project}.git"
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
#in_repo "git remote add origin git@github.com:$DESTINATION_USER/$REPOSITORY.git"
#in_repo "git push origin master"
#for branch in $BRANCHES; do
#  in_repo "git push origin $branch"
#done
git filter-branch -f --tree-filter mkdir -p manual && find . -maxdepth 1 | egrep -v '^\.|^\.\.|^\.git|^\.\/manual' | while read o; do git mv -f  manual; done 
