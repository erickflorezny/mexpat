#!/usr/bin/env bash
set -euo pipefail

: "${SUPABASE_URL:?SUPABASE_URL is required}"
: "${SUPABASE_ANON_KEY:?SUPABASE_ANON_KEY is required}"

mkdir -p Mexpat/Config
cat > Mexpat/Config/Secrets.ci.xcconfig <<EOF
// Generated in CI
SUPABASE_URL = ${SUPABASE_URL}
SUPABASE_ANON_KEY = ${SUPABASE_ANON_KEY}
EOF

echo "Generated Mexpat/Config/Secrets.ci.xcconfig"
