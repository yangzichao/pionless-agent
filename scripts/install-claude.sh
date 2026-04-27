#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR="${HOME}/.claude/plugins/pionless-agent"

bash "$ROOT_DIR/build.sh"

mkdir -p "${HOME}/.claude/plugins"
rm -rf "$TARGET_DIR"
cp -R "$ROOT_DIR/dist/claude-plugin" "$TARGET_DIR"

echo "Installed Claude Code plugin to:"
echo "  $TARGET_DIR"
echo ""
echo "This plugin ships these agents:"
echo "  deep-research, deep-research-pro, quick-research,"
echo "  deep-research-worker, deep-research-verifier, parallel-fix-worker"
echo ""
echo "For GitHub marketplace install, Claude Code users can also run:"
echo "  /plugin marketplace add yangzichao/pionless-agent"
echo "  /plugin install pionless-agent@pionless-agent-marketplace"
echo ""
echo "For development you can also run:"
echo "  claude --plugin-dir $ROOT_DIR/dist/claude-plugin"
