#!/bin/bash
set -e

source .env

if [ -z "$REPOS_DIR" ]; then
    echo "Error: Environment variable REPOS_DIR is not set."
    exit 1
fi

# link small scripts to under ignored directory
for i in $(fd -g '_*.sh');
do
    echo "ln -sf $PWD/$i $REPOS_DIR/$i"
    mkdir -p $(dirname $REPOS_DIR/$i)
    ln -sf $PWD/$i $REPOS_DIR/$i
done
