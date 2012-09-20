branch=$1
die() {
  echo $1 && exit 1
}
[ -n "$branch" ] || die 'I need a branch'
git remote  | while read remote; do 
  git pull -s subtree $remote $branch
done
