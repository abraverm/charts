#!/bin/bash
set -x
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -u|--username)
    export USERNAME="$2"
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

until $(bundle exec rake db:create)
do
  echo "Try again"
  sleep 5
done

until $(bundle exec rake db:migrate)
do
  echo "Try again"
  sleep 5
done

until [ ! -f assets.lock ]
do
  echo "Other node compiles assets, waiting"
  sleep 5
done

touch assets.lock
bundle exec rake assets:precompile
rm -rf  assets.lock

ADMIN=$(expect <<'EOF'
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
