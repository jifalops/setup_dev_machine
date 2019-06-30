#!/bin/bash

if [ "$1" == 'backup' ]; then
  find -maxdepth 2 -mindepth 2 -name .git -type d -exec git -C {} config --get remote.origin.url \; >"repos.txt"
  git add "repos.txt"
  git commit -m "Updated repos."
  git push -u origin master
elif [ "$1" == 'clone' ]; then
  git pull origin master
  if [ -f "repos.txt" ]; then
    while IFS= read -r line; do
      git clone "$line"
    done <"repos.txt"
  fi
else
  echo '
Usage: workspace_repos.sh COMMAND

COMMANDS
backup        Find all the git repos that are a direct child of the current
              directory, and write their origin remote to "repos.txt". Commit
              the changes and push to origin master.
clone         Pull from origin master and then run git clone on each line of
              "repos.txt".
'
fi
