#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$ROOT_DIR/src"
DIST_DIR="$ROOT_DIR/dist"
PLUGINS_DIR="$ROOT_DIR/plugins"
PLATFORMS_DIR="$ROOT_DIR/platforms"
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
# Step 2: Assemble per-plugin outputs (dist + committed repo plugins)
# ---------------------------------------------------------------------------
#
# Membership lives in src/plugins.json. For each plugin we produce three
# parallel layouts that share the same skill/agent bodies:
#
#   plugins/<plugin>/               committed plugin (serves both platforms)
#   dist/<plugin>/claude-plugin/    publish-ready Claude Code package
#   dist/<plugin>/codex-plugin/     publish-ready Codex package
#
# The Codex layout strips skill frontmatter to name + description only
# (matching the platform's expectations). The repo plugin and Claude dist
# retain the metadata block.

/usr/bin/python3 - "$ROOT_DIR" <<'PYTHON'
import json
import pathlib
import re
import shutil
import sys

root = pathlib.Path(sys.argv[1])
src = root / "src"
plugins_cfg = json.loads((src / "plugins.json").read_text())["plugins"]

shared_skills = root / "shared" / "skills"
mcp_json = root / "shared" / ".mcp.json"
claude_agents_built = root / "platforms" / "claude-code" / "agents"
codex_agents_built = root / "platforms" / "codex" / "agents"
plugins_dir = root / "plugins"
dist_dir = root / "dist"

# --- Wipe outputs cleanly --------------------------------------------------
if dist_dir.exists():
    shutil.rmtree(dist_dir)
dist_dir.mkdir()

for plugin_name in plugins_cfg:
    committed = plugins_dir / plugin_name
    if committed.exists():
        shutil.rmtree(committed)

# --- Validation: every src agent/skill must belong to exactly one plugin ---
all_src_agents = {p.stem for p in (src / "agents").glob("*.md")}
all_src_skills = {p.name for p in (src / "skills").iterdir() if p.is_dir() and (p / "SKILL.md").exists()}

claimed_agents = []
claimed_skills = []
for plugin_name, membership in plugins_cfg.items():
    claimed_agents.extend(membership.get("agents", []))
    claimed_skills.extend(membership.get("skills", []))

dup_agents = {a for a in claimed_agents if claimed_agents.count(a) > 1}
dup_skills = {s for s in claimed_skills if claimed_skills.count(s) > 1}
if dup_agents:
    sys.exit(f"  ✗ Agents claimed by multiple plugins: {sorted(dup_agents)}")
if dup_skills:
    sys.exit(f"  ✗ Skills claimed by multiple plugins: {sorted(dup_skills)}")

orphan_agents = all_src_agents - set(claimed_agents)
orphan_skills = all_src_skills - set(claimed_skills)
if orphan_agents:
    sys.exit(f"  ✗ Agents in src/agents/ not claimed by any plugin in src/plugins.json: {sorted(orphan_agents)}")
if orphan_skills:
    sys.exit(f"  ✗ Skills in src/skills/ not claimed by any plugin in src/plugins.json: {sorted(orphan_skills)}")

missing_agents = set(claimed_agents) - all_src_agents
missing_skills = set(claimed_skills) - all_src_skills
if missing_agents:
    sys.exit(f"  ✗ Plugin manifest references missing agents: {sorted(missing_agents)}")
if missing_skills:
    sys.exit(f"  ✗ Plugin manifest references missing skills: {sorted(missing_skills)}")

# --- Skill frontmatter filters --------------------------------------------
CODEX_KEEP = ("name:", "description:")
REPO_KEEP_TOP = ("name:", "description:", "metadata:")
REPO_FORBIDDEN_TOP = ("model:", "allowed-tools:", "tools:", "spawns-agents:")


def filter_codex_skill_fm(lines):
    """Codex SKILL.md keeps only name + description (incl. multi-line scalars)."""
    kept = []
    in_kept_multiline = False
    for line in lines:
        is_indented = line.startswith(" ") or line.startswith("\t")
        stripped = line.strip()
        if not is_indented and stripped:
            in_kept_multiline = False
            if any(stripped.startswith(k) for k in CODEX_KEEP):
                kept.append(line)
                if stripped in {"description: |", "description: >",
                                "description: |-", "description: >-"}:
                    in_kept_multiline = True
            continue
        if is_indented and in_kept_multiline:
            kept.append(line)
            continue
        if not stripped and in_kept_multiline:
            kept.append(line)
    return kept


def filter_repo_skill_fm(lines):
    """Repo/Claude SKILL.md keeps name, description, metadata; drops runtime-authority keys."""
    kept = []
    in_kept_multiline = False
    in_kept_block = False
    in_dropped_block = False
    for line in lines:
        is_indented = line.startswith(" ") or line.startswith("\t")
        stripped = line.strip()
        if not is_indented and stripped:
            in_kept_multiline = False
            in_kept_block = False
            in_dropped_block = False
            if any(stripped.startswith(k) for k in REPO_FORBIDDEN_TOP):
                in_dropped_block = True
                continue
            if any(stripped.startswith(k) for k in REPO_KEEP_TOP):
                kept.append(line)
                if stripped == "metadata:" or stripped.endswith(":"):
                    in_kept_block = True
                if stripped in {"description: |", "description: >",
                                "description: |-", "description: >-"}:
                    in_kept_multiline = True
                continue
            in_dropped_block = True
            continue
        if is_indented and (in_kept_multiline or in_kept_block):
            kept.append(line)
            continue
        if not stripped and (in_kept_multiline or in_kept_block):
            kept.append(line)
    return kept


def rewrite_skill_frontmatter(plugin_root, keep_fn):
    for path in plugin_root.rglob("SKILL.md"):
        text = path.read_text()
        m = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.DOTALL)
        if not m:
            continue
        kept = keep_fn(m.group(1).splitlines())
        if kept:
            path.write_text("---\n" + "\n".join(kept) + "\n---\n" + m.group(2))


# --- Per-plugin assembly ---------------------------------------------------
def copy_skills(dest_root, skill_names):
    skills_out = dest_root / "skills"
    skills_out.mkdir()
    for sname in sorted(skill_names):
        shutil.copytree(shared_skills / sname, skills_out / sname)


def copy_claude_agents(dest_root, agent_names):
    out = dest_root / "agents"
    out.mkdir()
    for aname in sorted(agent_names):
        shutil.copy(claude_agents_built / f"{aname}.md", out / f"{aname}.md")


def copy_codex_agents(dest_root, agent_names, dir_name):
    out = dest_root / dir_name
    out.mkdir()
    for aname in sorted(agent_names):
        shutil.copy(codex_agents_built / f"{aname}.toml", out / f"{aname}.toml")


print("Built plugins:")
for plugin_name, membership in plugins_cfg.items():
    agents = set(membership["agents"])
    skills = set(membership["skills"])

    claude_manifest_src = root / "platforms" / "claude-code" / plugin_name / ".claude-plugin"
    codex_manifest_src = root / "platforms" / "codex" / plugin_name / ".codex-plugin"
    if not claude_manifest_src.is_dir():
        sys.exit(f"  ✗ Missing Claude manifest: {claude_manifest_src}")
    if not codex_manifest_src.is_dir():
        sys.exit(f"  ✗ Missing Codex manifest:  {codex_manifest_src}")

    # 1) Claude dist
    claude_dist = dist_dir / plugin_name / "claude-plugin"
    claude_dist.mkdir(parents=True)
    copy_skills(claude_dist, skills)
    shutil.copy(mcp_json, claude_dist / ".mcp.json")
    shutil.copytree(claude_manifest_src, claude_dist / ".claude-plugin")
    copy_claude_agents(claude_dist, agents)
    rewrite_skill_frontmatter(claude_dist, filter_repo_skill_fm)

    # 2) Codex dist
    codex_dist = dist_dir / plugin_name / "codex-plugin"
    codex_dist.mkdir(parents=True)
    copy_skills(codex_dist, skills)
    shutil.copy(mcp_json, codex_dist / ".mcp.json")
    shutil.copytree(codex_manifest_src, codex_dist / ".codex-plugin")
    copy_codex_agents(codex_dist, agents, "agent-templates")
    rewrite_skill_frontmatter(codex_dist, filter_codex_skill_fm)

    # 3) Committed repo plugin (serves both platforms)
    repo = plugins_dir / plugin_name
    repo.mkdir(parents=True)
    copy_skills(repo, skills)
    shutil.copy(mcp_json, repo / ".mcp.json")
    shutil.copytree(claude_manifest_src, repo / ".claude-plugin")
    shutil.copytree(codex_manifest_src, repo / ".codex-plugin")
    copy_claude_agents(repo, agents)
    copy_codex_agents(repo, agents, "agent-templates")
    rewrite_skill_frontmatter(repo, filter_repo_skill_fm)

    print(f"  {plugin_name}:")
    print(f"    agents: {sorted(agents)}")
    print(f"    skills: {sorted(skills)}")
    print(f"    Claude dist: dist/{plugin_name}/claude-plugin/")
    print(f"    Codex  dist: dist/{plugin_name}/codex-plugin/")
    print(f"    Repo plugin: plugins/{plugin_name}/")
PYTHON
