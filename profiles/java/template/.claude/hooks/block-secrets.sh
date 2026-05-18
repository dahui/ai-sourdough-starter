#!/usr/bin/env bash
# block-secrets.sh — PreToolUse hook for Write|Edit
#
# Second line of defense beyond settings.json permissions.deny. Catches:
#   - Direct writes to secret-bearing filenames
#   - Writes whose CONTENT looks like a secret (API keys, AWS creds,
#     private keys) regardless of filename
#
# Exit 0 = allow. Exit 2 = block.

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty')

# 1. Filename-based block (defense-in-depth; settings.json deny is primary)
case "$FILE_PATH" in
  *.env|*.env.*|*/.env|*/.env.*|*.pem|*.key|*id_rsa*|*credentials.json|*credentials.yaml|*credentials.yml)
    cat <<EOF >&2
Blocked: write to secret-bearing file path: $FILE_PATH

Secrets must not live in source. Use the profile's secret-management
convention (env vars at runtime, a secrets manager, or .env.example with
placeholder values).
EOF
    exit 2
    ;;
esac

# 2. Content-based heuristic block. Conservative patterns to avoid noise.
if [[ -n "$CONTENT" ]]; then
  # AWS access key ID
  if echo "$CONTENT" | grep -qE 'AKIA[0-9A-Z]{16}'; then
    echo "Blocked: content appears to contain an AWS access key (AKIA...)." >&2
    exit 2
  fi
  # AWS secret access key (40-char base64-ish near "aws_secret")
  if echo "$CONTENT" | grep -qiE 'aws_secret_access_key[[:space:]]*[:=][[:space:]]*["'\'']?[A-Za-z0-9/+=]{40}'; then
    echo "Blocked: content appears to contain an AWS secret access key." >&2
    exit 2
  fi
  # PEM private key block (require BOTH BEGIN and END markers to avoid
  # false-positives in docs that just describe the pattern).
  if echo "$CONTENT" | grep -qE -- '-----BEGIN (RSA |EC |DSA |OPENSSH |PGP )?PRIVATE KEY-----' \
     && echo "$CONTENT" | grep -qE -- '-----END (RSA |EC |DSA |OPENSSH |PGP )?PRIVATE KEY-----'; then
    echo "Blocked: content appears to contain a private key block." >&2
    exit 2
  fi
  # GitHub fine-grained personal access token
  if echo "$CONTENT" | grep -qE 'github_pat_[A-Za-z0-9_]{22,}'; then
    echo "Blocked: content appears to contain a GitHub personal access token." >&2
    exit 2
  fi
  # Generic GitHub token
  if echo "$CONTENT" | grep -qE 'ghp_[A-Za-z0-9]{36}'; then
    echo "Blocked: content appears to contain a GitHub token (ghp_...)." >&2
    exit 2
  fi
  # Slack token
  if echo "$CONTENT" | grep -qE 'xox[abprs]-[A-Za-z0-9-]{10,}'; then
    echo "Blocked: content appears to contain a Slack token." >&2
    exit 2
  fi
fi

exit 0
