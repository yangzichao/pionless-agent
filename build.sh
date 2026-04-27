#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$ROOT_DIR/src"
DIST_DIR="$ROOT_DIR/dist"
CLAUDE_DIST="$DIST_DIR/claude-plugin"
CODEX_DIST="$DIST_DIR/codex-plugin"
REPO_PLUGIN_DIR="$ROOT_DIR/plugins/pionless-agent"
LOCK_DIR="$ROOT_DIR/.build.lock"

while ! mkdir "$LOCK_DIR" 2>/dev/null; do
  sleep 0.1
done

cleanup() {
  rmdir "$LOCK_DIR"
}

trap cleanup EXIT

# ---------------------------------------------------------------------------
# Step 0: Generate platform-specific agents from src/agents/ (single source)
# ---------------------------------------------------------------------------

/usr/bin/python3 - "$SRC_DIR" "$ROOT_DIR" <<'PYTHON'
import pathlib, re, sys, json

src_dir = pathlib.Path(sys.argv[1])
root_dir = pathlib.Path(sys.argv[2])

agents_src = src_dir / "agents"
claude_agents = root_dir / "platforms" / "claude-code" / "agents"
codex_agents = root_dir / "platforms" / "codex" / "agents"

claude_agents.mkdir(parents=True, exist_ok=True)
codex_agents.mkdir(parents=True, exist_ok=True)

# Clear old generated files
for f in claude_agents.glob("*.md"):
    f.unlink()
for f in codex_agents.glob("*.toml"):
    f.unlink()


def parse_frontmatter(text):
    """Parse YAML-ish frontmatter from markdown. Returns (dict, body)."""
    match = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.DOTALL)
    if not match:
        return {}, text
    raw = match.group(1)
    body = match.group(2)

    fm = {}
    current_key = None
    current_list = None
    current_nested = None
    nested_key = None
    lines = raw.splitlines()

    for i, line in enumerate(lines):
        # Bare key (e.g., "skills:" or "codex:") — look ahead to decide list vs object
        if re.match(r"^(\w[\w-]*):\s*$", line):
            key = line.strip().rstrip(":")
            # Peek at next non-empty line to decide type
            next_line = ""
            for j in range(i + 1, len(lines)):
                if lines[j].strip():
                    next_line = lines[j]
                    break
            if next_line.startswith("  - "):
                # It's a list
                fm[key] = []
                current_list = fm[key]
                current_nested = None
                nested_key = None
            else:
                # It's a nested object
                fm[key] = {}
                nested_key = key
                current_nested = fm[key]
                current_list = None
            current_key = key
            continue

        # Nested key-value inside an object
        if current_nested is not None and line.startswith("  "):
            stripped = line.strip()
            m = re.match(r'^([\w_-]+):\s+(.+)$', stripped)
            if m:
                k, v = m.group(1), m.group(2)
                # Parse list values like ["a", "b"]
                if v.startswith("[") and v.endswith("]"):
                    items = [x.strip().strip('"').strip("'") for x in v[1:-1].split(",")]
                    current_nested[k] = [x for x in items if x]
                else:
                    current_nested[k] = v.strip('"').strip("'")
                continue

        # Top-level list item (continuation of a list key)
        if line.startswith("  - ") and current_list is not None:
            current_list.append(line.strip()[2:].strip())
            continue

        # Top-level key: value
        m = re.match(r'^([\w_-]+):\s+(.+)$', line)
        if m:
            key, val = m.group(1), m.group(2)
            current_nested = None
            nested_key = None
            current_list = None
            fm[key] = val
            current_key = key
            continue

    return fm, body


def escape_toml_string(s):
    """Escape a Python string for inclusion inside a TOML basic (double-quoted) string."""
    out = []
    for ch in s:
        if ch == '\\':
            out.append('\\\\')
        elif ch == '"':
            out.append('\\"')
        elif ch == '\b':
            out.append('\\b')
        elif ch == '\f':
            out.append('\\f')
        elif ch == '\n':
            out.append('\\n')
        elif ch == '\r':
            out.append('\\r')
        elif ch == '\t':
            out.append('\\t')
        elif ord(ch) < 0x20 or ord(ch) == 0x7f:
            out.append(f'\\u{ord(ch):04x}')
        else:
            out.append(ch)
    return ''.join(out)


def to_toml_value(val):
    """Convert a Python value to a TOML-compatible string."""
    if isinstance(val, list):
        items = ", ".join(f'"{escape_toml_string(str(v))}"' for v in val)
        return f"[{items}]"
    if isinstance(val, str):
        return f'"{escape_toml_string(val)}"'
    return str(val)


for md_path in sorted(agents_src.glob("*.md")):
    text = md_path.read_text()
    fm, body = parse_frontmatter(text)
    name = fm.get("name", md_path.stem)

    # --- Generate Claude .md ---
    claude_fm_lines = []
    for key, val in fm.items():
        if isinstance(val, list):
            claude_fm_lines.append(f"{key}:")
            for item in val:
                claude_fm_lines.append(f"  - {item}")
        else:
            claude_fm_lines.append(f"{key}: {val}")

    claude_text = "---\n" + "\n".join(claude_fm_lines) + "\n---\n" + body
    (claude_agents / md_path.name).write_text(claude_text)

    # --- Generate Codex .toml ---
    skills_list = fm.get("skills", [])
    if isinstance(skills_list, str):
        skills_list = [skills_list]

    toml_lines = []
    toml_lines.append(f'name = {to_toml_value(name)}')
    if "description" in fm:
        toml_lines.append(f'description = {to_toml_value(fm["description"])}')

    # Developer instructions = body text
    body_escaped = body.strip().replace('\\', '\\\\').replace('"""', '\\"\\"\\"')
    toml_lines.append(f'developer_instructions = """\n{body_escaped}\n"""')

    # Skills config
    for skill_name in skills_list:
        toml_lines.append("")
        toml_lines.append("[[skills.config]]")
        toml_lines.append(f'path = {to_toml_value(f"__PIONLESS_PLUGIN_ROOT__/skills/{skill_name}/SKILL.md")}')
        toml_lines.append("enabled = true")

    (codex_agents / f"{md_path.stem}.toml").write_text("\n".join(toml_lines) + "\n")

print("  Agents generated from src/agents/")
PYTHON

# ---------------------------------------------------------------------------
# Step 1: Copy canonical-tree skills from src/skills/ into shared/skills/
# ---------------------------------------------------------------------------
#
# Each src/skills/<name>/ directory is a self-contained skill package per
# docs/ideal-design/01-skill-anatomy.md: SKILL.md + optional references/,
# assets/, scripts/. We copy the tree verbatim — no include expansion, no
# fragment composition. The published skill is exactly what the source says.

/usr/bin/python3 - "$SRC_DIR" "$ROOT_DIR" <<'PYTHON'
import pathlib, shutil, sys

src_dir = pathlib.Path(sys.argv[1])
root_dir = pathlib.Path(sys.argv[2])
skills_src = src_dir / "skills"
shared_skills = root_dir / "shared" / "skills"

# Clean old expanded skills to avoid stale leftovers
if shared_skills.exists():
    shutil.rmtree(shared_skills)
shared_skills.mkdir(parents=True)

copied = []
for skill_dir in sorted(skills_src.iterdir()):
    if not skill_dir.is_dir():
        continue
    if not (skill_dir / "SKILL.md").exists():
        # Not a skill directory — skip silently. Surfaces a helpful error
        # later if someone forgets the SKILL.md.
        continue

    out_dir = shared_skills / skill_dir.name
    shutil.copytree(skill_dir, out_dir)

    # Drop any author-side caches/test artifacts that should not ship with the
    # installed skill. These are explicitly listed in 01-skill-anatomy.md as
    # "what does not belong in a skill folder" once published.
    for cache in ("tests", "__pycache__"):
        for path in out_dir.rglob(cache):
            if path.is_dir():
                shutil.rmtree(path)

    copied.append(skill_dir.name)

print(f"  Skills copied to shared/skills/: {', '.join(copied)}")
PYTHON

# ---------------------------------------------------------------------------
# Step 2: Build dist packages
# ---------------------------------------------------------------------------

rm -rf "$CLAUDE_DIST" "$CODEX_DIST" "$REPO_PLUGIN_DIR"
mkdir -p "$CLAUDE_DIST" "$CODEX_DIST"

# Copy expanded skills to both dists
cp -R "$ROOT_DIR/shared/skills" "$CLAUDE_DIST/"
cp -R "$ROOT_DIR/shared/skills" "$CODEX_DIST/"

# Copy MCP config
cp "$ROOT_DIR/shared/.mcp.json" "$CLAUDE_DIST/"
cp "$ROOT_DIR/shared/.mcp.json" "$CODEX_DIST/"

# Platform-specific manifests
cp -R "$ROOT_DIR/platforms/claude-code/.claude-plugin" "$CLAUDE_DIST/"
cp -R "$ROOT_DIR/platforms/codex/.codex-plugin" "$CODEX_DIST/"

# Claude agents (generated in Step 0)
if [ -d "$ROOT_DIR/platforms/claude-code/agents" ]; then
  cp -R "$ROOT_DIR/platforms/claude-code/agents" "$CLAUDE_DIST/"
fi

# Claude hooks
if [ -d "$ROOT_DIR/platforms/claude-code/hooks" ]; then
  cp -R "$ROOT_DIR/platforms/claude-code/hooks" "$CLAUDE_DIST/"
fi

# Claude LSP config
if [ -f "$ROOT_DIR/platforms/claude-code/.lsp.json" ]; then
  cp "$ROOT_DIR/platforms/claude-code/.lsp.json" "$CLAUDE_DIST/"
fi

# Codex app config
if [ -f "$ROOT_DIR/platforms/codex/.app.json" ]; then
  cp "$ROOT_DIR/platforms/codex/.app.json" "$CODEX_DIST/"
fi

# Codex agent templates (generated in Step 0)
if [ -d "$ROOT_DIR/platforms/codex/agents" ]; then
  mkdir -p "$CODEX_DIST/agent-templates"
  cp -R "$ROOT_DIR/platforms/codex/agents/." "$CODEX_DIST/agent-templates/"
fi

# ---------------------------------------------------------------------------
# Step 3: Strip Codex skill frontmatter to name + description only
# ---------------------------------------------------------------------------
#
# Codex SKILL.md only consumes name/description for routing. The new
# canonical frontmatter also has a `metadata:` block (author, version,
# pionless.* tags) — we drop that on Codex but retain it for Claude/repo.

/usr/bin/python3 - "$CODEX_DIST" <<'PYTHON'
import pathlib
import re
import sys

codex_root = pathlib.Path(sys.argv[1])
KEEP_KEYS = ("name:", "description:")


def strip_to_name_description(frontmatter_lines):
    """Keep only name and description (with multi-line description blocks).

    Drops every other top-level key, including the `metadata:` block and any
    legacy `model:` / `allowed-tools:` fields if they appear.
    """
    kept = []
    in_kept_multiline = False  # True while inside a description: |... block
    in_dropped_block = False   # True while inside a non-kept top-level key (e.g. metadata:)

    for line in frontmatter_lines:
        is_indented = line.startswith(" ") or line.startswith("\t")
        stripped = line.strip()

        if not is_indented and stripped:
            # New top-level key — decide whether to keep it.
            in_kept_multiline = False
            in_dropped_block = False
            if any(stripped.startswith(k) for k in KEEP_KEYS):
                kept.append(line)
                # Detect multi-line scalar style: `description: |`, `>`, `|-`, `>-`.
                if stripped in {
                    "description: |", "description: >",
                    "description: |-", "description: >-",
                }:
                    in_kept_multiline = True
            else:
                in_dropped_block = True
            continue

        # Indented continuation line.
        if is_indented:
            if in_kept_multiline:
                kept.append(line)
            # If in_dropped_block, drop silently.
            continue

        # Blank line — preserve only if we are still inside something kept.
        if not stripped and in_kept_multiline:
            kept.append(line)

    return kept


for path in codex_root.rglob("SKILL.md"):
    text = path.read_text()
    match = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.DOTALL)
    if not match:
        continue

    body = match.group(2)
    kept = strip_to_name_description(match.group(1).splitlines())
    if kept:
        path.write_text("---\n" + "\n".join(kept) + "\n---\n" + body)

print("Built:")
print(f"  Claude Code: {codex_root.parent / 'claude-plugin'}")
print(f"  Codex:       {codex_root}")
PYTHON

# ---------------------------------------------------------------------------
# Step 4: Build the committed repo plugin (serves both platforms)
# ---------------------------------------------------------------------------

mkdir -p "$ROOT_DIR/plugins"
mkdir -p "$REPO_PLUGIN_DIR"

# Expanded skills
cp -R "$ROOT_DIR/shared/skills" "$REPO_PLUGIN_DIR/"
cp "$ROOT_DIR/shared/.mcp.json" "$REPO_PLUGIN_DIR/"

# Both platform manifests
cp -R "$ROOT_DIR/platforms/claude-code/.claude-plugin" "$REPO_PLUGIN_DIR/"
cp -R "$ROOT_DIR/platforms/codex/.codex-plugin" "$REPO_PLUGIN_DIR/"

# Claude agents
if [ -d "$ROOT_DIR/platforms/claude-code/agents" ]; then
  cp -R "$ROOT_DIR/platforms/claude-code/agents" "$REPO_PLUGIN_DIR/"
fi

if [ -d "$ROOT_DIR/platforms/claude-code/hooks" ]; then
  cp -R "$ROOT_DIR/platforms/claude-code/hooks" "$REPO_PLUGIN_DIR/"
fi

if [ -f "$ROOT_DIR/platforms/claude-code/.lsp.json" ]; then
  cp "$ROOT_DIR/platforms/claude-code/.lsp.json" "$REPO_PLUGIN_DIR/"
fi

if [ -f "$ROOT_DIR/platforms/codex/.app.json" ]; then
  cp "$ROOT_DIR/platforms/codex/.app.json" "$REPO_PLUGIN_DIR/"
fi

# Codex agent templates
if [ -d "$ROOT_DIR/platforms/codex/agents" ]; then
  mkdir -p "$REPO_PLUGIN_DIR/agent-templates"
  cp -R "$ROOT_DIR/platforms/codex/agents/." "$REPO_PLUGIN_DIR/agent-templates/"
fi

# Defense-in-depth: strip any runtime-authority frontmatter that may have
# crept into a skill source. Per docs/ideal-design/01-skill-anatomy.md,
# skills must NOT declare model/tools/spawn — those belong to the host.
# We keep name, description, and the metadata block (author, version, tags).
/usr/bin/python3 - "$REPO_PLUGIN_DIR" <<'PYTHON'
import pathlib
import re
import sys

plugin_root = pathlib.Path(sys.argv[1])
KEEP_TOP_KEYS = ("name:", "description:", "metadata:")
FORBIDDEN_TOP_KEYS = ("model:", "allowed-tools:", "tools:", "spawns-agents:")


def filter_frontmatter(frontmatter_lines):
    kept = []
    in_kept_multiline = False
    in_kept_block = False  # True while inside metadata: (an indented YAML object)
    in_dropped_block = False

    for line in frontmatter_lines:
        is_indented = line.startswith(" ") or line.startswith("\t")
        stripped = line.strip()

        if not is_indented and stripped:
            # New top-level key.
            in_kept_multiline = False
            in_kept_block = False
            in_dropped_block = False
            if any(stripped.startswith(k) for k in FORBIDDEN_TOP_KEYS):
                # Defensive: drop the whole block.
                in_dropped_block = True
                continue
            if any(stripped.startswith(k) for k in KEEP_TOP_KEYS):
                kept.append(line)
                if stripped == "metadata:" or stripped.endswith(":"):
                    # `metadata:` is a nested object — keep its indented children.
                    in_kept_block = True
                if stripped in {
                    "description: |", "description: >",
                    "description: |-", "description: >-",
                }:
                    in_kept_multiline = True
                continue
            # Unknown top-level key — drop to be safe.
            in_dropped_block = True
            continue

        if is_indented:
            if in_kept_multiline or in_kept_block:
                kept.append(line)
            continue

        if not stripped and (in_kept_multiline or in_kept_block):
            kept.append(line)

    return kept


for path in plugin_root.rglob("SKILL.md"):
    text = path.read_text()
    match = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.DOTALL)
    if not match:
        continue

    body = match.group(2)
    kept = filter_frontmatter(match.group(1).splitlines())
    if kept:
        path.write_text("---\n" + "\n".join(kept) + "\n---\n" + body)
PYTHON

echo "  Repo plugin: $REPO_PLUGIN_DIR"
