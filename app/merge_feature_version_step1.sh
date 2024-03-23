#!/bin/bash

set -euo pipefail

function check_project_is_feature_branch () {
  PROJECT_DIR_PATH=$1
  FEATURE_VERSION=$2
  pushd $PROJECT_DIR_PATH > /dev/null

  BRANCH=$(git branch --contains | cut -d " " -f 2 | tr -d '\n')
  if [ $BRANCH != $FEATURE_VERSION ]; then
    echo "[error] ${FEATURE_VERSION} ではありません。"
    echo "[error] ${PROJECT_DIR_PATH} は ${BRANCH} です。"
    exit 1
  fi
  echo "[info] ${PROJECT_DIR_PATH} は ${FEATURE_VERSION} です。"

  popd > /dev/null
}

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

function push_project_commit () {
  PROJECT_DIR_PATH=$1
  FEATURE_VERSION=$2
  ORIGIN_FROM=$3
  ORIGIN_TO=$4
  pushd $PROJECT_DIR_PATH > /dev/null

  NOT_PUSH_COMMIT_CNT=$(git log --oneline ${ORIGIN_FROM}/${FEATURE_VERSION}..${FEATURE_VERSION} | wc -l)
  if [[ $NOT_PUSH_COMMIT_CNT -ne 0 ]]; then
    echo "[info] ${PROJECT_DIR_PATH} の新ブランチをpushします。 "
    git push $ORIGIN_TO $FEATURE_VERSION
  else
    echo "[info] ${PROJECT_DIR_PATH} の新ブランチはpush済みです。"
  fi

  popd > /dev/null
}

function delete_project_new_branch () {
  PROJECT_DIR_PATH=$1
  FEATURE_VERSION=$2
  ORIGIN_TO=$3
  pushd $PROJECT_DIR_PATH > /dev/null

  git checkout master > /dev/null 2>&1
  git branch -d $FEATURE_VERSION
  git push $ORIGIN_TO --delete $FEATURE_VERSION
  echo "[info] ${PROJECT_DIR_PATH} の ${FEATURE_VERSION} をdeleteしました。"

  popd > /dev/null
}

function create_pull_request () {
  PROJECT_DIR_PATH=$1
  FEATURE_VERSION=$2
  pushd $PROJECT_DIR_PATH > /dev/null

  echo "========== Merge pull request ==========" 
  gh pr create --base master --head $FEATURE_VERSION --title "merge: ${FEATURE_VERSION} from xdevkit-room-version-manager" --body ""
  echo "========================================"

  popd > /dev/null
}

function push_project () {
  PROJECT_DIR_PATH=$1
  FEATURE_VERSION=$2
  ORIGIN_FROM=$3
  ORIGIN_TO=$4
  pushd $PROJECT_DIR_PATH > /dev/null

  git fetch > /dev/null 2>&1
  FEATURE_COMMIT_CNT=$(git log --oneline ${ORIGIN_FROM}/master..${ORIGIN_TO}/${FEATURE_VERSION} | wc -l)

  popd > /dev/null

  if [[ $FEATURE_COMMIT_CNT -eq 0 ]]; then
    echo "[warn] ${PROJECT_DIR_PATH} の新ブランチにコミットがありません。"
    delete_project_new_branch $PROJECT_DIR_PATH $FEATURE_VERSION $ORIGIN_TO
  else
    echo "[info] ${PROJECT_DIR_PATH} の新ブランチを使用します。 "
    push_project_commit $PROJECT_DIR_PATH $FEATURE_VERSION $ORIGIN_FROM $ORIGIN_TO
    create_pull_request $PROJECT_DIR_PATH $FEATURE_VERSION
  fi
}

function update_submodule () {
  PROJECT_DIR_PATH=$1
  FEATURE_VERSION=$2
  pushd $PROJECT_DIR_PATH > /dev/null

  SUBMODULE_DIR_PATH_LIST=$(cat .gitmodules | grep "path = " | awk '{ printf $3 "\n" }')
  echo "$SUBMODULE_DIR_PATH_LIST" | while read SUBMODULE_DIR_PATH; do
    check_project_is_feature_branch $SUBMODULE_DIR_PATH $FEATURE_VERSION
    check_status_is_clean $SUBMODULE_DIR_PATH
    push_project $SUBMODULE_DIR_PATH $FEATURE_VERSION "origin" "github"
  done

  popd > /dev/null
}


function switch_gitmodules_master () {
  PROJECT_DIR_PATH=$1
  pushd $PROJECT_DIR_PATH > /dev/null

  sed -i -e "s/branch = .*/branch = master/g" .gitmodules
  echo "[info] サブモジュールはすべて master に切り替わりました。"

  popd > /dev/null
}

function commit_submodule () {
  PROJECT_DIR_PATH=$1
  pushd $PROJECT_DIR_PATH > /dev/null

  git add .
  git commit -a -m 'update: .gitmodules and submodule for merge'
  echo "[info] サブモジュールの設定変更をcommitしました。"

  popd > /dev/null
}

function main () {
  FEATURE_VERSION=$1
  echo "[info] FEATURE_VERSION: $FEATURE_VERSION"
  if [[ $FEATURE_VERSION != v0.* ]]; then
    echo "[error] 不正なブランチ名です。v0.1 などを指定してください。"
    exit 1
  fi
 
  check_project_is_feature_branch "xlogin-jp-client-sample" $FEATURE_VERSION
  check_status_is_clean "xlogin-jp-client-sample"
  push_project "xlogin-jp-client-sample" $FEATURE_VERSION "origin" "origin"

  check_project_is_feature_branch "xlogin-jp" $FEATURE_VERSION
  check_status_is_clean "xlogin-jp"
  push_project "xlogin-jp" $FEATURE_VERSION "origin" "origin"
 
  check_project_is_feature_branch "xdevkit" $FEATURE_VERSION
  check_status_is_clean "xdevkit"
 
  update_submodule "xdevkit" $FEATURE_VERSION
  switch_gitmodules_master "xdevkit"
  commit_submodule "xdevkit"

  push_project "xdevkit" $FEATURE_VERSION "origin" "origin"

  echo "Merge all pull requests, then exec ./complete_merge.sh"
}

main ${1:-0}

