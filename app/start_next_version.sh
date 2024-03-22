#!/bin/bash

set -euo pipefail

function check_project_is_master_branch () {
  PROJECT_DIR_PATH=$1
  pushd $PROJECT_DIR_PATH > /dev/null

  BRANCH=$(git branch --contains | cut -d " " -f 2 | tr -d '\n')
  if [ $BRANCH != "master" ]; then
    echo "[error] master ではありません。"
    echo "[error] ${PROJECT_DIR_PATH} は ${BRANCH} です。"
    exit 1
  fi
  echo "[info] ${PROJECT_DIR_PATH} は master です。"

  popd > /dev/null
}

function check_submodule_is_master_branch () {
  PROJECT_DIR_PATH=$1
  pushd $PROJECT_DIR_PATH > /dev/null

  BRANCH=$(git branch --contains | cut -d " " -f 2 | tr -d '\n')
  if [[ $BRANCH != "master" ]]; then
    if [[ $BRANCH = "(HEAD" ]]; then
      echo "[warning] detached の状態です。masterに変更します。"
      git checkout master
      BRANCH=$(git branch --contains | cut -d " " -f 2 | tr -d '\n')
      if [[ $BRANCH != "master" ]]; then
        echo "[error] masterに変更できませんでした。"
        exit 1
      fi
    else
      echo "[error] master ではありません。"
      echo "[error] ${PROJECT_DIR_PATH} は ${BRANCH} です。"
      exit 1
    fi
  fi
  echo "[info] ${PROJECT_DIR_PATH} は master です。"

  popd > /dev/null
}

function switch_project_new_branch () {
  PROJECT_DIR_PATH=$1
  NEXT_VERSION=$2
  pushd $PROJECT_DIR_PATH > /dev/null

  git checkout -b $NEXT_VERSION

  BRANCH=$(git branch --contains | cut -d " " -f 2 | tr -d '\n')
  if [ $BRANCH != $NEXT_VERSION ]; then
    echo "[error] ブランチの切り替えに失敗しました。"
    exit 1
  fi
  echo "[info] ${PROJECT_DIR_PATH} は ${NEXT_VERSION} に切り替わりました。"

  popd > /dev/null
}

function check_gitmodules_has_master_branch () {
  PROJECT_DIR_PATH=$1
  pushd $PROJECT_DIR_PATH > /dev/null

  ANOTHER_BRANCH_CNT=$(cat .gitmodules | (grep "branch = v0." || true ) | wc -l)
  if [[ $ANOTHER_BRANCH_CNT -ne 0 ]]; then
    echo "[error] master 以外のブランチのサブモジュールが存在します。"
    exit 1
  fi
  echo "[info] サブモジュールはすべて master です。"

  popd > /dev/null
}

function push_project_new_branch () {
  PROJECT_DIR_PATH=$1
  NEXT_VERSION=$2
  ORIGIN=$3
  pushd $PROJECT_DIR_PATH > /dev/null

  git push $ORIGIN $NEXT_VERSION
  echo "[info] ${PROJECT_DIR_PATH} の ${NEXT_VERSION} をpushしました。"

  popd > /dev/null
}

function update_submodule () {
  PROJECT_DIR_PATH=$1
  NEXT_VERSION=$2
  pushd $PROJECT_DIR_PATH > /dev/null

  SUBMODULE_DIR_PATH_LIST=$(cat .gitmodules | grep "path = " | awk '{ printf $3 "\n" }')
  echo "$SUBMODULE_DIR_PATH_LIST" | while read SUBMODULE_DIR_PATH; do
    check_submodule_is_master_branch $SUBMODULE_DIR_PATH
    switch_project_new_branch $SUBMODULE_DIR_PATH $NEXT_VERSION
    push_project_new_branch $SUBMODULE_DIR_PATH $NEXT_VERSION "github"
  done

  popd > /dev/null
}

function exec_make_commit () {
  PROJECT_DIR_PATH=$1
  pushd $PROJECT_DIR_PATH > /dev/null

  make commit
  make
  echo "[info] ${PROJECT_DIR_PATH} のサブモジュールの更新をcommitしました。"

  popd > /dev/null
}

function main () {
  NEXT_VERSION=$1
  echo "[info] NEXT_VERSION: $NEXT_VERSION"
  if [[ $NEXT_VERSION != v0.* ]]; then
    echo "[error] 不正なブランチ名です。v0.1 などを指定してください。"
    exit 1
  fi
  
  check_project_is_master_branch "xlogin-jp-client-sample"
  switch_project_new_branch "xlogin-jp-client-sample" $NEXT_VERSION
  push_project_new_branch "xlogin-jp-client-sample" $NEXT_VERSION "origin"
  
  check_project_is_master_branch "xlogin-jp"
  switch_project_new_branch "xlogin-jp" $NEXT_VERSION
  push_project_new_branch "xlogin-jp" $NEXT_VERSION "origin"
  
  check_project_is_master_branch "xdevkit"
  check_gitmodules_has_master_branch "xdevkit"
  switch_project_new_branch "xdevkit" $NEXT_VERSION
  
  update_submodule "xdevkit" $NEXT_VERSION
  
  exec_make_commit "xdevkit"
  push_project_new_branch "xdevkit" $NEXT_VERSION "origin"
}

main ${1:-0}


