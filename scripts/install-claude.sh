#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

bash "$ROOT_DIR/build.sh"

mkdir -p "${HOME}/.claude/plugins"

PLUGINS=$(/usr/bin/python3 -c "import json,sys; print(' '.join(json.load(open('$ROOT_DIR/src/plugins.json'))['plugins'].keys()))")

for plugin in $PLUGINS; do
  target_dir="${HOME}/.claude/plugins/${plugin}"
  rm -rf "$target_dir"
  cp -R "$ROOT_DIR/dist/${plugin}/claude-plugin" "$target_dir"
  echo "Installed Claude Code plugin: $plugin"
  echo "  $target_dir"
  echo ""
done

echo "For GitHub marketplace install, Claude Code users can also run:"
echo "  /plugin marketplace add yangzichao/pionless-agent"
for plugin in $PLUGINS; do
  echo "  /plugin install ${plugin}@pionless-agent-marketplace"
done
echo ""
echo "For development you can also load a single plugin directly:"
for plugin in $PLUGINS; do
  echo "  claude --plugin-dir $ROOT_DIR/dist/${plugin}/claude-plugin"
done
