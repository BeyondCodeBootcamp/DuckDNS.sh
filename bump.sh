#!/bin/sh
set -e
set -u

my_version="${1-}"
if [ -z "${my_version}" ]; then
    echo "Usage: bump.sh v1.2.3"
    exit 1
fi

if ! git diff --quiet; then
    echo "Error: git status is dirty"
fi

if ! command -v sd > /dev/null; then
    echo "Install 'sd' first."
    echo "    curl https://webi.sh/sd | sh"
    exit 1
fi

my_commit_hash="$(
    git rev-parse --short HEAD
)"
my_commit_date="$(
    git show -s --format=%ci "${my_commit_hash}" |
        grep -E '20[0-9]{2}-[01][0-9]-[0123][0-9]'
)"
my_year="$(
    date '+%Y'
)"

sd 'my_version=.*' "my_version='${my_version}'" duckdns.sh
sd 'my_year=.*' "my_year='${my_year}'" duckdns.sh
sd 'my_date=.*' "my_date='${my_commit_date}'" duckdns.sh

git add ./duckdns.sh
git commit -m "chore(release): bump to ${my_version}"
git tag "${my_version}"

git describe --tags
