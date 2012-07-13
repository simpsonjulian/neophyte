for project in community advanced enterprise manual packaging; do 
  git remote add -f ${project} git://github.com/neo4j/${project}.git
  git merge -s ours --no-commit ${project}/master
  git read-tree --prefix=${project}/ -u ${project}/master
  git commit -m "Subtree merged in ${project}"
done
