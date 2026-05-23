#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_AGENT_DIR="${HOME}/.codex/agents"
MARKETPLACE_DIR="${HOME}/.agents/plugins"
MARKETPLACE_FILE="${MARKETPLACE_DIR}/marketplace.json"

bash "$ROOT_DIR/build.sh"

mkdir -p "${HOME}/.codex/plugins" "$TARGET_AGENT_DIR" "$MARKETPLACE_DIR"

PLUGINS=$(/usr/bin/python3 -c "import json,sys; print(' '.join(json.load(open('$ROOT_DIR/src/plugins.json'))['plugins'].keys()))")

for plugin in $PLUGINS; do
  target_plugin_dir="${HOME}/.codex/plugins/${plugin}"
  rm -rf "$target_plugin_dir"
  cp -R "$ROOT_DIR/dist/${plugin}/codex-plugin" "$target_plugin_dir"

  # Render this plugin's agent templates into ~/.codex/agents/ with absolute paths.
  /usr/bin/python3 - "$ROOT_DIR/dist/${plugin}/codex-plugin/agent-templates" "$TARGET_AGENT_DIR" "$target_plugin_dir" <<'PYTHON'
import pathlib
import sys

source_dir = pathlib.Path(sys.argv[1])
target_dir = pathlib.Path(sys.argv[2])
plugin_root = sys.argv[3]

if not source_dir.exists():
    sys.exit(0)

for path in source_dir.glob("*.toml"):
    content = path.read_text()
    content = content.replace("__PIONLESS_PLUGIN_ROOT__", plugin_root)
    (target_dir / path.name).write_text(content)
PYTHON

  echo "Installed Codex plugin: $plugin"
  echo "  plugin:  $target_plugin_dir"
done

# Register every plugin in the personal Codex marketplace.
/usr/bin/python3 - "$MARKETPLACE_FILE" $PLUGINS <<'PYTHON'
import json
import pathlib
import sys

marketplace_file = pathlib.Path(sys.argv[1])
plugin_names = sys.argv[2:]

data = {
    "name": "pionless-agent",
    "interface": {"displayName": "pionless-agent"},
    "plugins": [],
}

if marketplace_file.exists():
    data = json.loads(marketplace_file.read_text())

data.setdefault("name", "pionless-agent")
data.setdefault("interface", {}).setdefault("displayName", "pionless-agent")
data.setdefault("plugins", [])

# Drop any prior entries for plugins we are about to write.
data["plugins"] = [p for p in data["plugins"] if p.get("name") not in plugin_names]

for plugin_name in plugin_names:
    data["plugins"].append({
        "name": plugin_name,
        "source": {
            "source": "local",
            "path": f"./.codex/plugins/{plugin_name}",
        },
        "policy": {
            "installation": "AVAILABLE",
            "authentication": "ON_INSTALL",
        },
        "category": "Productivity",
    })

marketplace_file.write_text(json.dumps(data, indent=2) + "\n")
PYTHON

echo ""
echo "Installed Codex custom agents to:"
echo "  $TARGET_AGENT_DIR"
echo ""
echo "Updated personal marketplace:"
echo "  $MARKETPLACE_FILE"
echo ""
echo "Restart Codex to pick up the new agents and plugins."
