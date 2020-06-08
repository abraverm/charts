#!/bin/bash
set -x
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -f|--from)
    FROM="$2"
    shift
    shift
    ;;
    -t|--to)
    TO="$2"
    shift
    shift
    ;;
    -u|--username)
    exprot USERNAME="$2"
    shift
    shift
    ;;
    -p|--password)
    export PASSWORD="$2"
    shift
    shift
    ;;
    *)
    POSITIONAL+=("$1")
    shift
    ;;
esac
done
set -- "${POSITIONAL[@]}"

rsync \
  -auv \
  --delete \
  --ignore-errors \
  --no-i-r \
  --omit-dir-times \
  --no-perms \
  --exclude "**/*.tar.gz" \
  --exclude "**/.travis.yml" \
  $FROM $TO

pushd $FROM
bundle exec rake db:create
bundle exec rake db:migrate

ADMIN=$(expect <'EOF'
  spawn bundle exec rake admin:create

  expect "Email:  "
  send -- "$env(USERNAME)\r"
  expect {
    "*already exists*" { send -- "n\r" }
    "Password:  " { 
      send -- "$env(PASSWORD)\r"
      expect "Repeate password:  "
      send -- "$env(PASSWORD)\r"
    }
  }
  expect "Ensuring*"
  expect "Account*"
  expect "Do you*"
  send -- "Y\r"
  expect "*Admin*"
  expect eof
EOF
)

echo "$ADMIN"
popd
