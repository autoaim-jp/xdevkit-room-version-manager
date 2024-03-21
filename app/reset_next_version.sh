#!/bin/bash

set -euo pipefail

function delete_project_new_branch () {
  PROJECT_DIR_PATH=$1
  NEXT_VERSION=$2
  ORIGIN=$3
  pushd $PROJECT_DIR_PATH > /dev/null
  set +e
  git checkout master > /dev/null 2>&1
  git branch -d $NEXT_VERSION
  git push $ORIGIN --delete $NEXT_VERSION
  set -e
  echo "[info] ${PROJECT_DIR_PATH} の ${NEXT_VERSION} をdeleteしました。"
  popd > /dev/null
}

function switch_submodule_master () {
  PROJECT_DIR_PATH=$1
  pushd $PROJECT_DIR_PATH > /dev/null
  sed -i -e "s/branch = .*/branch = master/g" .gitmodules
  echo "[info] サブモジュールはすべて master に切り替わりました。"
  popd > /dev/null
}

function reset_submodule () {
  PROJECT_DIR_PATH=$1
  SUBMODULE_DIR_PATH=$2
  NEXT_VERSION=$3
  pushd $PROJECT_DIR_PATH > /dev/null
  popd > /dev/null
}

function main () {
  NEXT_VERSION=$1
  echo "[info] NEXT_VERSION: $NEXT_VERSION"
  if [[ $NEXT_VERSION != v0.* ]]; then
    echo "[error] 不正なブランチ名です。v0.1 などを指定してください。"
    exit 1
  fi

#  delete_project_new_branch "xlogin-jp-client-sample" $NEXT_VERSION origin
#  delete_project_new_branch "xlogin-jp" $NEXT_VERSION origin
#  delete_project_new_branch "xdevkit" $NEXT_VERSION origin

  switch_submodule_master "xdevkit"

}
 
main ${1:-0}

