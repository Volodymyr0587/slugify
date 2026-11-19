#!/usr/bin/env bash
#
# Check test prerequisites, then execute the Bats test suite.
#
set -o nounset

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

if ! command -v bats >/dev/null 2>&1; then
    printf '%s\n' \
        "Bats is not installed or is not available in PATH." \
        "" \
        "Install Bats on Ubuntu/Debian:" \
        "  sudo apt update" \
        "  sudo apt install bats" \
        "" \
        "Then run:" \
        "  ./tests/run-tests.sh" >&2
    exit 127
fi

if ! command -v bash >/dev/null 2>&1; then
    printf '%s\n' "Bash is required but was not found." >&2
    exit 127
fi

if ! command -v iconv >/dev/null 2>&1; then
    printf '%s\n' \
        "Warning: iconv was not found. Accented Latin transliteration may be limited." >&2
fi

bash -n "$PROJECT_DIR/slugify" || exit $?
exec bats "$SCRIPT_DIR/slugify.bats"
