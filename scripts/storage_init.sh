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
    *)
    POSITIONAL+=("$1")
    shift
    ;;
esac
done
set -- "${POSITIONAL[@]}"

rsync \
  -au \
  --ignore-errors \
  --no-i-r \
  --omit-dir-times \
  --no-perms \
  --exclude "**/*.tar.gz" \
  --exclude "**/.travis.yml" \
  $FROM $TO

pushd $TO
bundle install --deployment --retry 3 --jobs 4 --verbose --without test development
# bundle exec rake plugin:install_all_official
pushd plugins
git clone https://github.com/discourse/docker_manager.git || true
git clone https://github.com/jonmbake/discourse-ldap-auth || true
git clone https://github.com/discourse/discourse-solved.git || true
git clone https://github.com/discourse/discourse-voting.git || true
git clone https://github.com/paviliondev/discourse-layouts.git || true
git clone https://github.com/paviliondev/discourse-question-answer || true
git clone https://github.com/discourse/discourse-data-explorer || true
popd
bundle exec rake plugin:install_all_gems
popd
