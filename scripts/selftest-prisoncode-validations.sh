#!/bin/sh

set -u

REPO_ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
PRISONCODE_BIN="$REPO_ROOT/prisoncode"

PASS_COUNT=0
FAIL_COUNT=0

setup_case_env() {
  case_dir="$1"

  mkdir -p "$case_dir/home/.config/opencode" "$case_dir/home/.prisoncode" "$case_dir/bin"

  printf '{"token":"test"}\n' > "$case_dir/auth.json"

  cat <<'EOF' > "$case_dir/home/.config/opencode/opencode.json"
{
  "share": "disabled",
  "disabled_providers": []
}
EOF

  cat <<'EOF' > "$case_dir/bin/docker"
#!/bin/sh
if [ "$1" = "image" ] && [ "$2" = "inspect" ]; then
  case "$4" in
    *org.prisoncode.packages_hash*)
      printf '%s\n' "${TEST_DOCKER_PACKAGES_HASH:-}"
      ;;
    *org.prisoncode.repo_path*)
      printf '%s\n' "${TEST_DOCKER_REPO_PATH:-$PWD}"
      ;;
  esac
  exit 0
fi

if [ "$1" = "run" ] || [ "$1" = "compose" ]; then
  exit 0
fi

exit 0
EOF
  chmod +x "$case_dir/bin/docker"
}

run_case() {
  name="$1"
  expected_code="$2"
  expected_text="$3"
  case_dir="$4"
  shift 4

  output_file="$case_dir/output.txt"

  env \
    HOME="$case_dir/home" \
    PATH="$case_dir/bin:$PATH" \
    PRISONCODE_AUTH_FILE="$case_dir/auth.json" \
    PRISONCODE_CONFIG_DIR="$case_dir/home/.config/opencode" \
    TEST_DOCKER_REPO_PATH="$REPO_ROOT" \
    "$PRISONCODE_BIN" "$@" >"$output_file" 2>&1
  actual_code=$?

  output=$(cat "$output_file")

  case_ok=1
  if [ "$actual_code" -ne "$expected_code" ]; then
    case_ok=0
  fi

  if [ -n "$expected_text" ]; then
    case "$output" in
      *"$expected_text"*) ;;
      *) case_ok=0 ;;
    esac
  fi

  if [ "$case_ok" -eq 1 ]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf 'PASS: %s\n' "$name"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf 'FAIL: %s\n' "$name"
    printf '  expected exit: %s\n' "$expected_code"
    printf '  actual exit:   %s\n' "$actual_code"
    if [ -n "$expected_text" ]; then
      printf '  expected text: %s\n' "$expected_text"
    fi
    printf '  output:\n%s\n' "$output"
  fi
}

TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/prisoncode-selftest.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT INT TERM

case_num=1

new_case_dir() {
  dir="$TMP_ROOT/case-$case_num"
  mkdir -p "$dir"
  setup_case_env "$dir"
  case_num=$((case_num + 1))
  printf '%s\n' "$dir"
}

case_dir=$(new_case_dir)
run_case "domains missing fails" 1 "must contain at least one allowed endpoint" "$case_dir"

case_dir=$(new_case_dir)
cat <<'EOF' > "$case_dir/home/.prisoncode/domains.txt"
# comment only

EOF
run_case "domains comments only fails" 1 "must contain at least one allowed endpoint" "$case_dir"

case_dir=$(new_case_dir)
cat <<'EOF' > "$case_dir/home/.prisoncode/domains.txt"
*
EOF
run_case "domains wildcard rejected" 1 "'*' in ~/.prisoncode/domains.txt is not supported" "$case_dir"

case_dir=$(new_case_dir)
cat <<'EOF' > "$case_dir/home/.prisoncode/domains.txt"
*
EOF
run_case "unrestricted skips domains validation" 0 "unrestricted network mode enabled" "$case_dir" --unrestricted-network

case_dir=$(new_case_dir)
rm -f "$case_dir/home/.config/opencode/opencode.json"
cat <<'EOF' > "$case_dir/home/.prisoncode/domains.txt"
api.openai.com
EOF
run_case "missing opencode.json fails" 1 "required config file not found" "$case_dir"

case_dir=$(new_case_dir)
cat <<'EOF' > "$case_dir/home/.config/opencode/opencode.json"
{ not json }
EOF
cat <<'EOF' > "$case_dir/home/.prisoncode/domains.txt"
api.openai.com
EOF
run_case "invalid opencode.json fails" 1 "invalid JSON in" "$case_dir"

case_dir=$(new_case_dir)
cat <<'EOF' > "$case_dir/home/.config/opencode/opencode.json"
{
  "share": "enabled",
  "disabled_providers": []
}
EOF
cat <<'EOF' > "$case_dir/home/.prisoncode/domains.txt"
api.openai.com
EOF
run_case "share must be disabled" 1 "must set \"share\": \"disabled\"" "$case_dir"

case_dir=$(new_case_dir)
cat <<'EOF' > "$case_dir/home/.config/opencode/opencode.json"
{
  "share": "disabled"
}
EOF
cat <<'EOF' > "$case_dir/home/.prisoncode/domains.txt"
api.openai.com
EOF
run_case "disabled_providers key required" 1 "must include \"disabled_providers\"" "$case_dir"

case_dir=$(new_case_dir)
cat <<'EOF' > "$case_dir/home/.config/opencode/opencode.json"
{
  "share": "disabled",
  "disabled_providers": "none"
}
EOF
cat <<'EOF' > "$case_dir/home/.prisoncode/domains.txt"
api.openai.com
EOF
run_case "disabled_providers must be array" 1 "must be an array" "$case_dir"

case_dir=$(new_case_dir)
cat <<'EOF' > "$case_dir/home/.prisoncode/domains.txt"
api.openai.com
EOF
run_case "valid config and domains pass" 0 "" "$case_dir"

printf '\nResults: %s passed, %s failed\n' "$PASS_COUNT" "$FAIL_COUNT"

if [ "$FAIL_COUNT" -ne 0 ]; then
  exit 1
fi
