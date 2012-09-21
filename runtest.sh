#!/bin/bash
set -x

die() {
  echo $1;exit 1
}

username=$1
password=$2
[ -n "$username" ] || die "Usage: $0 <github username> <password>"
[ -n "$password" ] || die "Usage: $0 <github username> <password>"

# create test repos
credentials="$username:$password"
curl -u $credentials -X DELETE https://api.github.com/repos/$username/repo1
curl -u $credentials -X DELETE https://api.github.com/repos/$username/repo2
sleep 10
curl -u $credentials -X POST https://api.github.com/user/repos -d '{"name":"repo1"}'
curl -u $credentials -X POST https://api.github.com/user/repos -d '{"name":"repo2"}'
sleep 10

number=1

commit_file() {
  local repo=$1
  local branch=$2
  local file="file-$repo-$branch-$number"

  git checkout $branch
  git pull origin master
  date > $file
  git add $file
  git commit -m "commit$number"
  git push origin $branch
  ((number++))
}

filenumber=1

populate() {
  local reponame=$1
  echo "populating $reponame"
  git init
  git remote add origin git@github.com:$username/$reponame.git
  touch README.md
  git add README.md
  git commit -m "commit0"
  git push origin master
  git checkout -b branch1
  git checkout -b branch2
  commit_file $reponame master
  commit_file $reponame branch1
  commit_file $reponame master
  commit_file $reponame branch2
  commit_file $reponame master
}

create_repo() {
  local reponame=$1
  local repo=`mktemp -d -t $reponame`
  (cd $repo && populate $reponame)
}

# populate repos
create_repo repo1
create_repo repo2

# perform merge
destination=`mktemp -d -t repomergeoutputdirectory`
./repo_merge.sh $destination $username "repo1 repo2" "branch1 branch2"

# assert commits/ files exists in the right places
