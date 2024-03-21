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

function switch_submodule_new_branch () {
  PROJECT_DIR_PATH=$1
  NEXT_VERSION=$2
  pushd $PROJECT_DIR_PATH > /dev/null
  sed -i -e "s/branch = master/branch = ${NEXT_VERSION}/g" .gitmodules
  echo "[info] サブモジュールはすべて ${NEXT_VERSION} に切り替わりました。"
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
  SUBMODULE_DIR_PATH=$1
  NEXT_VERSION=$2
  check_submodule_is_master_branch $SUBMODULE_DIR_PATH
  switch_project_new_branch $SUBMODULE_DIR_PATH $NEXT_VERSION
  push_project_new_branch $SUBMODULE_DIR_PATH $NEXT_VERSION github
}

function exec_make_and_commit () {
  PROJECT_DIR_PATH=$1
  NEXT_VERSION=$2
  pushd $PROJECT_DIR_PATH > /dev/null

  # make commit
  SUBMODULE_DIR_PATH_LIST=$(cat .gitmodules | grep "path = " | awk '{ printf $3 "\n" }')
  echo "$SUBMODULE_DIR_PATH_LIST" | while read SUBMODULE_DIR_PATH; do
    pushd $SUBMODULE_DIR_PATH > /dev/null
    DIFF_CNT=$(git status -s 2> /dev/null | wc -l)
    if [[ $DIFF_CNT -ne 0 ]]; then
      echo "[error] ${SUBMODULE_DIR_PATH} にコミットされていない変更があります。"
      exit 1
    fi

    git checkout master > /dev/null 2>&1
    git pull origin master > /dev/null 2>&1
    MERGE_RESULT=$(git merge --no-commit 2> /dev/null)
    git checkout $NEXT_VERSION > /dev/null 2>&1
    popd > /dev/null

    if [[ $MERGE_RESULT == "Already up to date." ]]; then
      echo "[warn] ${SUBMODULE_DIR_PATH} の新ブランチにコミットがありません。"
      git config -f .gitmodules --replace-all submodule.${SUBMODULE_DIR_PATH}.branch master
    else
      echo "[info] ${SUBMODULE_DIR_PATH} の新ブランチを使用します。 "
      git config -f .gitmodules --replace-all submodule.${SUBMODULE_DIR_PATH}.branch $NEXT_VERSION
    fi
  done

  make
  git add .
  git commit -a -m 'update: submodules'
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
  push_project_new_branch "xlogin-jp-client-sample" $NEXT_VERSION origin
  
  check_project_is_master_branch "xlogin-jp"
  switch_project_new_branch "xlogin-jp" $NEXT_VERSION
  push_project_new_branch "xlogin-jp" $NEXT_VERSION origin
  
  check_project_is_master_branch "xdevkit"
  check_gitmodules_has_master_branch "xdevkit"
  switch_project_new_branch "xdevkit" $NEXT_VERSION
  switch_submodule_new_branch "xdevkit" $NEXT_VERSION
  
  update_submodule "standalone/xdevkit-view-compiler" $NEXT_VERSION
  update_submodule "standalone/xdevkit-eslint" $NEXT_VERSION
  update_submodule "standalone/xdevkit-htpasswd" $NEXT_VERSION
  update_submodule "standalone/xdevkit-jsdoc" $NEXT_VERSION
  update_submodule "common/xdevkit-auth-router" $NEXT_VERSION
  update_submodule "common/xdevkit-setting" $NEXT_VERSION
  update_submodule "common/xdevkit-view-component" $NEXT_VERSION

  # submoduleの新ブランチで変更がある場合は.gitmodulesも新ブランチにしたほうがいい
  # そうでないならばmasterのほうがいい。なぜなら新ブランチは消すので。
  exec_make_and_commit "xdevkit" $NEXT_VERSION
  push_project_new_branch "xdevkit" $NEXT_VERSION origin
}

main ${1:-0}


