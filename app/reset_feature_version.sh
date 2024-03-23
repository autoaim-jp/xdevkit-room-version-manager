#!/bin/bash

set -euo pipefail

function check_status_is_clean () {
  PROJECT_DIR_PATH=$1
  pushd $PROJECT_DIR_PATH > /dev/null

  DIFF_CNT=$(git status -s 2> /dev/null | wc -l)
  if [[ $DIFF_CNT -ne 0 ]]; then
    echo "[error] ${PROJECT_DIR_PATH} にコミットされていない変更があります。"
    exit 1
  fi

  popd > /dev/null
}

function check_project_has_commit () {
  PROJECT_DIR_PATH=$1
  FEATURE_VERSION=$2
  ORIGIN=$3
  pushd $PROJECT_DIR_PATH > /dev/null

  git fetch > /dev/null 2>&1
  set +e
  FEATURE_COMMIT_CNT=$(git log --oneline ${ORIGIN}/master..${FEATURE_VERSION} 2> /dev/null | wc -l)
  set -e

  if [[ $FEATURE_COMMIT_CNT -ne 0 ]]; then
    echo "[warn] ${PROJECT_DIR_PATH} の新ブランチにコミットがあります。"
    git log ${ORIGIN}/master..${FEATURE_VERSION}
    show_continue_prompt "コミットを含むブランチを削除します。"
  fi

  popd > /dev/null
}

function delete_project_new_branch () {
  PROJECT_DIR_PATH=$1
  FEATURE_VERSION=$2
  ORIGIN=$3
  pushd $PROJECT_DIR_PATH > /dev/null

  git checkout master > /dev/null 2>&1 || true
  git branch -d $FEATURE_VERSION || true
  git push $ORIGIN --delete $FEATURE_VERSION || true
  echo "[info] ${PROJECT_DIR_PATH} の ${FEATURE_VERSION} をdeleteしました。"

  popd > /dev/null
}

function reset_submodule () {
  PROJECT_DIR_PATH=$1
  FEATURE_VERSION=$2
  pushd $PROJECT_DIR_PATH > /dev/null

  SUBMODULE_DIR_PATH_LIST=$(cat .gitmodules | grep "path = " | awk '{ printf $3 "\n" }')
  echo "$SUBMODULE_DIR_PATH_LIST" | while read SUBMODULE_DIR_PATH; do
    check_status_is_clean $SUBMODULE_DIR_PATH
    check_project_has_commit $SUBMODULE_DIR_PATH $FEATURE_VERSION "origin"
    delete_project_new_branch $SUBMODULE_DIR_PATH $FEATURE_VERSION "github"
  done

  popd > /dev/null
}

function show_continue_prompt () {
  PROMPT_MESSAGE=$1
  echo -n "${PROMPT_MESSAGE}続けますか？(y/n): "
  read INPUT_VALUE
  if [[ $INPUT_VALUE != "y" ]]; then
    echo "終了します。"
    exit 0
  fi
}

function main () {
  FEATURE_VERSION=$1
  echo "[info] FEATURE_VERSION: $FEATURE_VERSION"
  if [[ $FEATURE_VERSION != v0.* ]]; then
    echo "[error] 不正なブランチ名です。v0.1 などを指定してください。"
    exit 1
  fi

  show_continue_prompt "開発中のブランチをresetします。"
 
  check_status_is_clean "xlogin-jp-client-sample"
  check_project_has_commit "xlogin-jp-client-sample" $FEATURE_VERSION "origin"
  delete_project_new_branch "xlogin-jp-client-sample" $FEATURE_VERSION "origin"

  check_status_is_clean "xlogin-jp"
  check_project_has_commit "xlogin-jp" $FEATURE_VERSION "origin"
  delete_project_new_branch "xlogin-jp" $FEATURE_VERSION "origin"

  check_status_is_clean "xdevkit"
  check_project_has_commit "xdevkit" $FEATURE_VERSION "origin"
  delete_project_new_branch "xdevkit" $FEATURE_VERSION "origin"

  reset_submodule "xdevkit" $FEATURE_VERSION
}
 
main ${1:-0}

