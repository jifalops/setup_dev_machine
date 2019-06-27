#!/bin/bash

# get_origin() {

# }

# Find child dirs that are git repos
find -maxdepth 2 -mindepth 2 -name .git -type d -exec git -C {} config --get remote.origin.url \;

# | xargs ""

# Get this repo's remote
