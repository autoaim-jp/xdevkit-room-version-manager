#!/bin/bash

set -euo pipefail

function update_project () {
  PROJECT_DIR_PATH=$1
  ORIGIN_FROM=$2
  pushd $PROJECT_DIR_PATH > /dev/null

  git checkout master > /dev/null 2>&1 || true
  git pull $ORIGIN_FROM master > /dev/null 2>&1

  popd > /dev/null
}

function update_submodule_project () {
  PROJECT_DIR_PATH=$1
  pushd $PROJECT_DIR_PATH > /dev/null

  SUBMODULE_DIR_PATH_LIST=$(cat .gitmodules | grep "path = " | awk '{ printf $3 "\n" }')
  echo "$SUBMODULE_DIR_PATH_LIST" | while read SUBMODULE_DIR_PATH; do
    update_project $SUBMODULE_DIR_PATH "github"
  done

  popd > /dev/null
}

function main () {
  update_project "xlogin-jp" "origin"
  update_project "xlogin-jp-client-sample" "origin"
  update_project "xdevkit" "origin"
  update_submodule_project "xdevkit"
}

main

