#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR="${HOME}/.claude/plugins/gluon-agent"

bash "$ROOT_DIR/build.sh"

mkdir -p "${HOME}/.claude/plugins"
rm -rf "$TARGET_DIR"
cp -R "$ROOT_DIR/dist/claude-plugin" "$TARGET_DIR"

echo "Installed Claude Code plugin to:"
echo "  $TARGET_DIR"
echo ""
echo "This plugin ships named research subagents:"
echo "  deep-research, deep-research-pro, quick-research, research-worker, research-verifier"
echo ""
echo "For GitHub marketplace install, Claude Code users can also run:"
echo "  /plugin marketplace add yangzichao/gluon-agent"
echo "  /plugin install gluon-agent@gluon-agent-marketplace"
echo ""
echo "For development you can also run:"
echo "  claude --plugin-dir $ROOT_DIR/dist/claude-plugin"
