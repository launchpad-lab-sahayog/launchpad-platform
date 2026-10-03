#!/usr/bin/env bash
# Usage: ./bootstrap-repo.sh <org> <service-name> <owning-team>
set -euo pipefail
ORG="$1"; NAME="$2"; TEAM="${3:-service-team}"
TEMPLATE="$ORG/launchpad-service-template"
DIR="$(cd "$(dirname "$0")" && pwd)"

if gh repo view "$ORG/$NAME" >/dev/null 2>&1; then
  echo "Repo $ORG/$NAME exists, re-applying standards only"
else
  gh repo create "$ORG/$NAME" --template "$TEMPLATE" --public
  sleep 5
fi

gh repo edit "$ORG/$NAME" --add-topic launchpad \
  --enable-squash-merge --enable-merge-commit=false \
  --enable-rebase-merge=false --delete-branch-on-merge

gh api -X PUT "orgs/$ORG/teams/$TEAM/repos/$ORG/$NAME" -f permission=push
gh api -X PUT "orgs/$ORG/teams/platform-team/repos/$ORG/$NAME" -f permission=maintain

if ! gh api "repos/$ORG/$NAME/rulesets" --jq '.[].name' | grep -qx main-protection; then
  gh api -X POST "repos/$ORG/$NAME/rulesets" --input "$DIR/../rulesets/main-protection.json" > /dev/null
fi
echo "Ready: https://github.com/$ORG/$NAME"
