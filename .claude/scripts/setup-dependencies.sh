#!/bin/bash
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"
mkdir -p tmp log
LOG="tmp/session-start.log"
: > "$LOG"

step() {
  local name="$1"
  shift
  local started status=0
  started=$(date +%s.%N)
  "$@" >> "$LOG" 2>&1 || status=$?
  printf '%-18s %6.2fs\n' "$name" "$(echo "$(date +%s.%N) - $started" | bc)" | tee -a "$LOG"
  return $status
}

GEM_BINDIR="$(ruby -e 'print Gem.bindir')"
export PATH="$GEM_BINDIR:$PATH"
if [ -n "${CLAUDE_ENV_FILE:-}" ] && ! grep -qs "$GEM_BINDIR" "$CLAUDE_ENV_FILE"; then
  echo "export PATH=\"$GEM_BINDIR:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

BUNDLER_VERSION="$(awk '/^BUNDLED WITH/ { getline; print $1 }' Gemfile.lock)"
export BUNDLER_VERSION

install_bundler() {
  gem list --installed bundler --version "$BUNDLER_VERSION" > /dev/null ||
    gem install bundler --version "$BUNDLER_VERSION" --no-document
}

install_gems() {
  bundle check || bundle install --jobs "$(nproc)" --retry 3
}

prepare_databases() {
  bin/rails db:prepare db:test:prepare
}

step bundler install_bundler
step gems install_gems
step databases prepare_databases
