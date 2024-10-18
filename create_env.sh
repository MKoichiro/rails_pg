#!/bin/bash

set -eu

ENV_FILE_PATH=".env"

# .env ファイルを作成または上書きする関数
write_env_file() {
  cat <<EOF > $ENV_FILE_PATH
USER_NAME=$USER_NAME
GROUP_NAME=$GROUP_NAME
UID=$UID_TEMP
GID=$GID
DBMS=postgres
POSTGRES_HOST=$POSTGRES_HOST
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
EOF
}

# ユーザーからの入力を受け付ける関数
get_user_input() {
  read -p "Enter your user name: " -ei $(id -un) USER_NAME
  USER_NAME=${USER_NAME:-$(id -un)}  # デフォルト値を設定
  read -p "Enter your group name: " -ei $(id -gn) GROUP_NAME
  GROUP_NAME=${GROUP_NAME:-$(id -gn)}  # デフォルト値を設定
  read -p "Enter your UID: " -ei $(id -u) UID_TEMP
  UID_TEMP=${UID_TEMP:-$(id -u)}  # デフォルト値を設定
  read -p "Enter your GID: " -ei $(id -g) GID
  GID=${GID:-$(id -g)}  # デフォルト値を設定
  read -p "Enter Postgres host: " -ei db POSTGRES_HOST
  POSTGRES_HOST=${POSTGRES_HOST:-db}  # デフォルト値を設定
  read -p "Enter Postgres user: " -ei myuser POSTGRES_USER
  POSTGRES_USER=${POSTGRES_USER:-myuser}  # デフォルト値を設定
  read -p "Enter Postgres password: " -ei mypassword POSTGRES_PASSWORD
  POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-mypassword}  # デフォルト値を設定
}

# メイン処理
get_user_input

if [ -e $ENV_FILE_PATH ]; then
  echo "The .env file already exists. Do you want to overwrite it? (yes/no)"
  read answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    write_env_file
    echo "Overwrote the .env file."
    echo "------------------------"
    cat $ENV_FILE_PATH
    exit 0
  else
    echo "Keeping the existing .env file."
    exit 0
  fi
else
  write_env_file
  echo "Created a new .env file."
  echo "------------------------"
  cat $ENV_FILE_PATH
  exit 0
fi

# エラーが発生した場合
echo "An unexpected error occurred."
exit 1
