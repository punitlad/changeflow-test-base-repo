#!/usr/bin/env bash
# One-time GitHub-side setup for the native_auto_merge test target.
# Requires: gh CLI authenticated (`gh auth login`) with admin on the target owner/org.
set -euo pipefail

: "${GH_OWNER:?set GH_OWNER to your github user or org}"
: "${REPO_NAME:?set repo name}"
: "${REVIEWER_LOGIN:?set reviewer required for main check}"

echo "==> Creating branch ruleset on main (PR + required 'validate' check, NO required review)"
gh api -X POST "repos/$GH_OWNER/$REPO_NAME/rulesets" --input - >/dev/null <<EOF
{
  "name": "main-protection",
  "target": "branch",
  "enforcement": "active",
  "conditions": {"ref_name": {"include": ["refs/heads/main"], "exclude": []}},
  "rules": [
    {"type": "pull_request"},
    {
      "type": "required_status_checks",
      "parameters": {
        "required_status_checks": [{"context": "validate"}],
        "strict_required_status_checks_policy": true
      }
    }
  ]
}
EOF

echo "==> Creating 'production' environment with $REVIEWER_LOGIN as required reviewer"
REVIEWER_ID=$(gh api "users/$REVIEWER_LOGIN" --jq .id)
gh api -X PUT "repos/$GH_OWNER/$REPO_NAME/environments/production" --input - >/dev/null <<EOF
{
  "reviewers": [{"type": "User", "id": $REVIEWER_ID}],
  "deployment_branch_policy": null
}
EOF
