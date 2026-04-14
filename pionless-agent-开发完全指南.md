# pionless-agent 开发完全指南

> **pionless-agent** — 如同胶子将夸克束缚为质子，pionless-agent 将 Claude Code、Codex、Gemini CLI 等多个 AI 编程代理的能力粘合为一个统一的插件体系。一套 Skills、一份 MCP 配置、一个仓库，服务所有平台。

---

## 一、插件是什么？

Claude Code 插件是一个**自包含的目录**，通过标准化的结构扩展 Claude Code 的能力。你可以在插件中打包以下组件的任意组合：

| 组件 | 目录位置 | 作用 |
|------|---------|------|
| **Skills** | `skills/` | 技能指令文件（`SKILL.md`），Claude 可自动或手动调用 |
| **Agents** | `agents/` | 自定义子代理定义，用于专业化任务 |
| **Hooks** | `hooks/hooks.json` | 生命周期事件处理器（如文件保存后自动格式化） |
| **MCP Servers** | `.mcp.json` | Model Context Protocol 服务器，连接外部工具 |
| **LSP Servers** | `.lsp.json` | Language Server Protocol，提供代码智能补全 |
| **Settings** | `settings.json` | 插件启用时的默认配置 |
| **Manifest** | `.claude-plugin/plugin.json` | 插件元数据（唯一必须在 `.claude-plugin/` 内的文件） |

---

## 二、从零创建一个插件

### 2.1 目录结构总览

```
my-awesome-plugin/
├── .claude-plugin/
│   └── plugin.json              ← 插件清单（仅此文件放在这里）
├── skills/                      ← 技能目录
│   ├── code-review/
│   │   ├── SKILL.md
│   │   └── scripts/
│   │       └── lint.sh
│   └── deploy/
│       └── SKILL.md
├── agents/                      ← 自定义代理
│   ├── security-reviewer.md
│   └── test-writer.md
├── hooks/                       ← 生命周期钩子
│   └── hooks.json
├── .mcp.json                    ← MCP 服务器配置
├── .lsp.json                    ← LSP 服务器配置（可选）
├── settings.json                ← 默认设置（可选）
├── scripts/                     ← 共享脚本
├── README.md
└── LICENSE
```

### 2.2 快速脚手架

```bash
# 1. 创建插件目录
mkdir my-plugin && cd my-plugin

# 2. 创建清单
mkdir .claude-plugin
cat > .claude-plugin/plugin.json << 'EOF'
{
  "name": "my-plugin",
  "description": "一个示例插件，包含代码审查和部署功能",
  "version": "1.0.0",
  "author": {
    "name": "Your Name"
  },
  "license": "MIT",
  "keywords": ["code-review", "deploy"]
}
EOF

# 3. 创建第一个 Skill
mkdir -p skills/hello
cat > skills/hello/SKILL.md << 'EOF'
---
name: hello
description: 向用户打招呼并提供帮助。当用户说"你好"或需要引导时触发。
---

向用户 "$ARGUMENTS" 热情打招呼，询问他们今天需要什么帮助。
EOF

# 4. 本地测试
cd ..
claude --plugin-dir ./my-plugin
```

启动后，可以通过 `/my-plugin:hello 张三` 来调用技能。

---

## 三、各组件详解

### 3.1 Skills（技能）

Skills 是插件中最核心、最常用的组件。每个 Skill 是一个包含 `SKILL.md` 的目录。

#### SKILL.md 结构

```markdown
---
name: code-review
description: >
  审查代码质量、安全漏洞和最佳实践。当用户提到"审查代码"、"code review"、
  "检查我的代码"时触发。即使用户没有明确说"审查"，只要上下文涉及代码质量
  评估也应该触发。
disable-model-invocation: false   # true = 仅用户可调用，Claude 不会自动触发
user-invocable: true              # false = 仅 Claude 内部调用
allowed-tools: Read, Grep, Bash   # 限制可用工具（可选）
model: sonnet                     # 覆盖模型（可选）
effort: high                      # 推理力度: low/medium/high/max
context: fork                     # 在隔离的子代理中运行
agent: Explore                    # 使用的代理类型
paths: "src/**,lib/**"            # 激活路径模式
argument-hint: "[文件路径]"        # 自动补全提示
---

# 代码审查技能

你是一位资深代码审查专家。请对 `$ARGUMENTS` 进行全面审查。

## 审查维度

1. **代码质量**: 命名规范、函数长度、复杂度
2. **安全性**: 注入漏洞、认证缺陷、数据泄露
3. **性能**: 算法复杂度、内存使用、N+1 查询
4. **可维护性**: 测试覆盖、文档、耦合度

## 输出格式

对每个发现的问题，给出：
- 严重等级（Critical / Warning / Info）
- 问题描述
- 具体代码位置
- 修复建议
```

#### 可用的字符串替换变量

| 变量 | 说明 |
|------|------|
| `$ARGUMENTS` | 用户传入的全部参数 |
| `$ARGUMENTS[0]` 或 `$0` | 第一个参数 |
| `${CLAUDE_SESSION_ID}` | 当前会话 ID |
| `${CLAUDE_SKILL_DIR}` | 当前 Skill 的目录路径 |

#### Skill 目录的完整结构

```
code-review/
├── SKILL.md           ← 主指令（必需）
├── scripts/           ← 可执行脚本（用于确定性/重复任务）
│   └── lint.sh
├── references/        ← 参考文档（按需加载到上下文）
│   ├── python-style.md
│   └── security-checklist.md
├── assets/            ← 输出用的资源文件（模板、图标等）
└── examples/          ← 示例输出
    └── sample-review.md
```

**三级加载机制**：
1. **元数据**（name + description）— 始终在上下文中（约 100 词）
2. **SKILL.md 正文** — Skill 被触发时加载（建议 < 500 行）
3. **捆绑资源** — 按需读取（脚本可以直接执行而无需加载到上下文）

### 3.2 Agents（自定义代理）

Agents 定义在 `agents/` 目录中，每个 `.md` 文件就是一个代理。

```markdown
---
name: security-reviewer
description: 专门审查代码中的安全漏洞和最佳实践
model: sonnet
effort: medium
maxTurns: 20
disallowedTools: Write, Edit
---

你是一名安全专家。审查代码时关注以下方面：

- SQL 注入漏洞
- 认证绕过风险
- 数据暴露问题
- 密码学弱点
- OWASP Top 10

发现问题后，给出具体的修复方案和代码示例。
```

#### Agent 可用的 frontmatter 字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `name` | string | 代理标识符 |
| `description` | string | 何时使用、做什么 |
| `model` | string | 使用的模型（默认继承会话） |
| `effort` | string | low / medium / high / max |
| `maxTurns` | number | 最大交互轮次 |
| `tools` | string | 允许使用的工具 |
| `disallowedTools` | string | 禁止使用的工具 |
| `skills` | string | 预加载的技能 |
| `isolation` | string | `"worktree"` 表示 git 隔离 |

### 3.3 Hooks（生命周期钩子）

Hooks 让你在 Claude Code 的生命周期事件中注入自定义逻辑。

**`hooks/hooks.json`**：

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format-code.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo '欢迎使用 my-plugin！'"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/safety-check.sh"
          }
        ]
      }
    ]
  }
}
```

#### 可用的生命周期事件

| 事件 | 触发时机 |
|------|---------|
| `SessionStart` | 会话开始 |
| `UserPromptSubmit` | 用户提交提示词 |
| `PreToolUse` | 工具调用前 |
| `PostToolUse` | 工具调用后 |
| `PostToolUseFailure` | 工具调用失败后 |
| `SubagentStart` / `SubagentStop` | 子代理启停 |
| `Stop` | 会话结束 |
| `FileChanged` | 文件变更 |
| `PreCompact` / `PostCompact` | 上下文压缩前后 |

#### Hook 类型

| 类型 | 说明 |
|------|------|
| `command` | 执行 shell 脚本或二进制文件 |
| `http` | POST 事件 JSON 到 URL |
| `prompt` | 用 LLM 评估 |
| `agent` | 运行一个验证代理 |

### 3.4 MCP Servers

MCP（Model Context Protocol）是一个开放协议，让 Claude 能调用外部工具和服务。

**`.mcp.json`**（放在插件根目录）：

```json
{
  "mcpServers": {
    "my-database": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
      "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
      "env": {
        "DB_PATH": "${CLAUDE_PLUGIN_DATA}/data",
        "API_KEY": "${USER_CONFIG:api_key}"
      }
    },
    "my-api-server": {
      "command": "npx",
      "args": ["-y", "@myorg/mcp-server@latest"],
      "cwd": "${CLAUDE_PLUGIN_ROOT}"
    },
    "remote-server": {
      "type": "sse",
      "url": "https://my-mcp-server.example.com/sse"
    }
  }
}
```

#### 关键环境变量

| 变量 | 说明 |
|------|------|
| `${CLAUDE_PLUGIN_ROOT}` | 插件安装目录（只读，更新时会变） |
| `${CLAUDE_PLUGIN_DATA}` | 持久化数据目录（更新后不丢失） |
| `${USER_CONFIG:key}` | 用户配置值（见下方 userConfig） |

#### 用户可配置项（userConfig）

在 `plugin.json` 中定义用户启用插件时需要填写的配置：

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "userConfig": {
    "api_key": {
      "type": "string",
      "description": "你的 API 密钥",
      "required": true
    },
    "region": {
      "type": "string",
      "description": "服务区域",
      "default": "us-east-1"
    }
  }
}
```

### 3.5 LSP Servers（语言服务器）

提供代码智能补全、跳转定义等能力。

**`.lsp.json`**：

```json
{
  "typescript": {
    "command": "typescript-language-server",
    "args": ["--stdio"],
    "extensionToLanguage": {
      ".ts": "typescript",
      ".tsx": "typescriptreact"
    }
  },
  "python": {
    "command": "pyright-langserver",
    "args": ["--stdio"],
    "extensionToLanguage": {
      ".py": "python"
    }
  }
}
```

---

## 四、开发与测试

### 4.1 本地开发模式

```bash
# 加载插件进行开发测试（不需要安装）
claude --plugin-dir ./my-plugin

# 同时加载多个插件
claude --plugin-dir ./plugin-a --plugin-dir ./plugin-b

# 修改代码后重新加载
# 在 Claude Code 中输入：
/reload-plugins
```

### 4.2 调试技巧

1. **查看 Skill 触发情况**：在 SKILL.md 的 description 中写清楚触发条件，测试各种表述是否能正确触发
2. **Hook 调试**：Hook 脚本的 stdout/stderr 会被捕获，可以用 `echo` 输出调试信息
3. **MCP Server 调试**：先单独运行 MCP Server 确保工具正常工作，再集成到插件中

---

## 五、打包与分发

### 5.1 版本管理

在 `plugin.json` 中使用语义化版本：

```json
{
  "version": "1.2.3"
}
```

规则：MAJOR（破坏性变更）.MINOR（新功能）.PATCH（修复）

### 5.2 创建 Marketplace（插件市场）

如果你有多个插件，可以创建一个 marketplace 来管理它们：

```
my-marketplace/
├── .claude-plugin/
│   └── marketplace.json
└── plugins/
    ├── code-reviewer/
    └── deploy-helper/
```

**`marketplace.json`**：

```json
{
  "name": "my-plugins",
  "owner": {
    "name": "Your Name",
    "email": "you@example.com"
  },
  "metadata": {
    "description": "我的插件合集"
  },
  "plugins": [
    {
      "name": "code-reviewer",
      "source": "./plugins/code-reviewer",
      "description": "代码审查自动化",
      "version": "1.0.0"
    },
    {
      "name": "deploy-helper",
      "source": {
        "source": "github",
        "repo": "myorg/deploy-helper",
        "ref": "v2.0.0"
      }
    }
  ]
}
```

#### 支持的插件来源（source）

| 类型 | 格式 | 示例 |
|------|------|------|
| 本地路径 | `"./path"` | `"./plugins/my-plugin"` |
| GitHub | `{ "source": "github", "repo": "owner/repo", "ref": "v1.0" }` | 从 GitHub 仓库拉取 |
| Git URL | `{ "source": "url", "url": "https://..." }` | 任意 Git 仓库 |
| Git 子目录 | `{ "source": "git-subdir", "url": "...", "path": "..." }` | 仓库内的子目录 |
| npm | `{ "source": "npm", "package": "@org/pkg", "version": "^1.0" }` | npm 包 |

### 5.3 提交到官方市场

你可以将插件提交到 Anthropic 的官方插件市场：

- Claude.ai 用户: https://claude.ai/settings/plugins/submit
- Console 用户: https://platform.claude.com/plugins/submit

---

## 六、安装与使用

### 6.1 安装插件

```bash
# 添加一个 marketplace
/plugin marketplace add owner/repo

# 或从本地目录
/plugin marketplace add ./my-marketplace

# 安装插件
/plugin install code-reviewer@my-plugins

# 管理插件
/plugin enable code-reviewer
/plugin disable code-reviewer
/plugin uninstall code-reviewer
/plugin update code-reviewer

# 列出所有可用插件
/plugin
```

### 6.2 安装作用域

| 作用域 | 配置文件 | 说明 |
|--------|---------|------|
| `user` | `~/.claude/settings.json` | 所有项目可用 |
| `project` | `.claude/settings.json` | 项目级，可通过版本控制共享给团队 |
| `local` | `.claude/settings.local.json` | 项目级，gitignore 中不共享 |

```bash
claude plugin install my-plugin --scope project
```

### 6.3 团队配置

在项目的 `.claude/settings.json` 中为团队预配置插件：

```json
{
  "extraKnownMarketplaces": {
    "company-tools": {
      "source": {
        "source": "github",
        "repo": "myorg/claude-plugins"
      }
    }
  },
  "enabledPlugins": {
    "code-formatter@company-tools": true,
    "deploy-helper@company-tools": true
  }
}
```

---

## 七、完整示例：全栈插件

以下是一个包含所有组件的完整示例：

```
fullstack-plugin/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── review/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── python-rules.md
│   │       └── ts-rules.md
│   └── deploy/
│       ├── SKILL.md
│       └── scripts/
│           └── deploy.sh
├── agents/
│   ├── security-scanner.md
│   └── test-generator.md
├── hooks/
│   └── hooks.json
├── .mcp.json
├── scripts/
│   ├── format.sh
│   └── validate.sh
├── settings.json
├── README.md
└── LICENSE
```

**`plugin.json`**：
```json
{
  "name": "fullstack-plugin",
  "description": "全栈开发工具套件：代码审查、安全扫描、自动部署",
  "version": "1.0.0",
  "author": { "name": "Your Team" },
  "license": "MIT",
  "keywords": ["fullstack", "review", "deploy", "security"],
  "userConfig": {
    "deploy_target": {
      "type": "string",
      "description": "部署目标环境 (staging / production)",
      "default": "staging"
    }
  }
}
```

---

## 八、Codex 插件系统与跨平台开发

好消息：截至 2026 年 3 月，OpenAI Codex 已经推出了完整的插件系统，而且架构与 Claude Code 的插件系统**高度相似**。两者都采用了 `SKILL.md` 模式、`.mcp.json` 配置、`plugin.json` 清单，使得跨平台开发变得非常可行。

### 8.1 两者对比（2026 年 3 月最新）

| 特性 | Claude Code | OpenAI Codex |
|------|-------------|-------------|
| 插件清单 | `.claude-plugin/plugin.json` | `.codex-plugin/plugin.json` |
| Skills | `skills/*/SKILL.md`（支持丰富的 frontmatter） | `skills/*/SKILL.md`（frontmatter 仅 name + description） |
| MCP 服务器 | `.mcp.json` | `.mcp.json` |
| 应用集成 | 无专用文件 | `.app.json`（连接 Slack、Figma 等服务） |
| 自定义代理 | `agents/*.md`（完整的子代理系统） | 通过 Agents SDK 编排多代理 |
| 生命周期钩子 | `hooks/hooks.json`（丰富的事件类型） | user prompt hook（v0.116.0+） |
| LSP 服务器 | `.lsp.json` | 无原生支持 |
| 上下文指令 | `CLAUDE.md` | `AGENTS.md` / `codex.md` |
| 安装位置 | `~/.claude/plugins/` | `~/.codex/plugins/cache/` |
| Marketplace | 支持 GitHub/Git/npm 来源 | `marketplace.json`（本地/用户/仓库级别） |
| 官方插件目录 | 已开放提交 | 即将开放（"coming soon"） |

**核心发现**：两者在 Skills 和 MCP 配置上几乎完全兼容；主要差异在于 Claude Code 拥有更丰富的 Skill frontmatter 字段、完整的 Hooks 系统和原生多代理支持，而 Codex 独有 `.app.json` 应用集成。

### 8.2 跨平台插件架构（推荐）

由于两者结构高度相似，你可以用一个**统一的目录结构**同时服务两个平台，只需维护极薄的适配层：

```
my-universal-plugin/
├── shared/                            ← 两个平台共享的核心内容
│   ├── skills/                        ← SKILL.md 文件（两边通用！）
│   │   ├── code-review/
│   │   │   └── SKILL.md
│   │   └── deploy/
│   │       ├── SKILL.md
│   │       └── scripts/
│   │           └── deploy.sh
│   ├── .mcp.json                      ← MCP 配置（两边格式相同！）
│   └── scripts/                       ← 共享脚本
│       ├── lint.sh
│       └── format.sh
│
├── claude/                            ← Claude Code 专有内容
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── agents/                        ← Claude 专有：子代理定义
│   │   └── security-scanner.md
│   ├── hooks/                         ← Claude 专有：生命周期钩子
│   │   └── hooks.json
│   └── .lsp.json                      ← Claude 专有：LSP 服务器
│
├── codex/                             ← Codex 专有内容
│   ├── .codex-plugin/
│   │   └── plugin.json
│   └── .app.json                      ← Codex 专有：应用集成
│
├── build.sh                           ← 构建脚本：组装两个平台的最终插件
└── README.md
```

### 8.3 构建脚本：一键生成双平台插件

```bash
#!/bin/bash
# build.sh — 从共享源码构建 Claude Code 和 Codex 两个版本的插件

set -e

# 清理
rm -rf dist/claude-plugin dist/codex-plugin

# ===== 构建 Claude Code 插件 =====
echo "构建 Claude Code 插件..."
mkdir -p dist/claude-plugin
cp -r shared/skills dist/claude-plugin/
cp shared/.mcp.json dist/claude-plugin/
cp -r shared/scripts dist/claude-plugin/
cp -r claude/.claude-plugin dist/claude-plugin/
[ -d claude/agents ] && cp -r claude/agents dist/claude-plugin/
[ -d claude/hooks ] && cp -r claude/hooks dist/claude-plugin/
[ -f claude/.lsp.json ] && cp claude/.lsp.json dist/claude-plugin/

# ===== 构建 Codex 插件 =====
echo "构建 Codex 插件..."
mkdir -p dist/codex-plugin
cp -r shared/skills dist/codex-plugin/
cp shared/.mcp.json dist/codex-plugin/
cp -r shared/scripts dist/codex-plugin/
cp -r codex/.codex-plugin dist/codex-plugin/
[ -f codex/.app.json ] && cp codex/.app.json dist/codex-plugin/

# ===== 处理 SKILL.md 兼容性 =====
# Codex 的 SKILL.md 只支持 name 和 description，需要去掉 Claude 专有的 frontmatter 字段
echo "处理 Codex SKILL.md 兼容性..."
python3 << 'PYTHON'
import os, re, yaml

codex_skills = "dist/codex-plugin/skills"
for root, dirs, files in os.walk(codex_skills):
    for f in files:
        if f != "SKILL.md":
            continue
        path = os.path.join(root, f)
        with open(path) as fh:
            content = fh.read()

        match = re.match(r'^---\n(.*?)\n---\n(.*)', content, re.DOTALL)
        if not match:
            continue

        meta = yaml.safe_load(match.group(1))
        body = match.group(2)

        # Codex 只保留 name 和 description
        codex_meta = {}
        if "name" in meta:
            codex_meta["name"] = meta["name"]
        if "description" in meta:
            codex_meta["description"] = meta["description"]

        # 替换 Claude 专有变量为通用形式
        body = body.replace("${CLAUDE_PLUGIN_ROOT}", "${PLUGIN_ROOT}")
        body = body.replace("${CLAUDE_PLUGIN_DATA}", "${PLUGIN_DATA}")
        body = body.replace("${CLAUDE_SKILL_DIR}", "${SKILL_DIR}")
        body = body.replace("${CLAUDE_SESSION_ID}", "${SESSION_ID}")

        new_content = "---\n" + yaml.dump(codex_meta, allow_unicode=True) + "---\n" + body
        with open(path, "w") as fh:
            fh.write(new_content)

print("  SKILL.md 兼容性处理完成")
PYTHON

echo ""
echo "构建完成！"
echo "  Claude Code 插件: dist/claude-plugin/"
echo "  Codex 插件:       dist/codex-plugin/"
echo ""
echo "测试方法："
echo "  claude --plugin-dir dist/claude-plugin"
echo "  将 dist/codex-plugin 复制到 ~/.codex/plugins/ 并配置 marketplace.json"
```

### 8.4 SKILL.md 跨平台编写技巧

由于两个平台都使用 `SKILL.md`，但支持的 frontmatter 字段不同，推荐这样编写：

```markdown
---
# ===== 通用字段（两个平台都支持）=====
name: code-review
description: >
  审查代码质量、安全漏洞和最佳实践。当用户提到
  "审查代码"、"code review"、"检查我的代码"时触发。

# ===== Claude Code 专有字段（Codex 会忽略未知字段）=====
allowed-tools: Read, Grep, Bash
effort: high
context: fork
---

# 代码审查

审查 $ARGUMENTS 的代码质量。

## 步骤

1. 使用静态分析工具检查代码
2. 审查安全漏洞
3. 检查性能问题
4. 生成审查报告
```

**关键原则**：把 `name` 和 `description` 写在前面（两边通用），Claude 专有字段放后面。Codex 遇到不认识的 frontmatter 字段时会忽略，不会报错。

### 8.5 .mcp.json 跨平台配置

两个平台的 `.mcp.json` 格式完全兼容，可以直接共用：

```json
{
  "mcpServers": {
    "my-database": {
      "command": "node",
      "args": ["./scripts/db-server.js"],
      "env": {
        "DB_PATH": "./data/app.db"
      }
    }
  }
}
```

唯一需要注意的是**路径变量**：Claude 使用 `${CLAUDE_PLUGIN_ROOT}`，而 Codex 使用相对路径。推荐在共享的 `.mcp.json` 中使用相对路径，然后在构建脚本中根据平台进行替换。

### 8.6 平台差异的处理策略

| 差异点 | 解决方案 |
|--------|---------|
| Claude 的 `agents/` 目录 | Codex 无对应物；在 Codex 中，可通过 Agents SDK 编排多代理，或将代理逻辑写入 SKILL.md |
| Claude 的 `hooks/` | Codex 仅有 user prompt hook；复杂钩子用 git hooks 或 CI 替代 |
| Codex 的 `.app.json` | Claude 无对应物；在 Claude 中，通过 MCP 服务器连接外部服务 |
| Claude 的 `.lsp.json` | Codex 无对应物；LSP 功能由 IDE 集成提供 |
| Skill frontmatter 差异 | 构建脚本自动裁剪 Codex 不支持的字段 |
| 路径变量 (`${CLAUDE_PLUGIN_ROOT}` 等) | 构建脚本中做字符串替换 |

### 8.7 安装与测试

**Claude Code 端**：

```bash
# 开发测试
claude --plugin-dir dist/claude-plugin

# 正式安装
/plugin marketplace add ./my-marketplace
/plugin install my-plugin@my-marketplace
```

**Codex 端**：

```bash
# 方法一：复制到本地插件目录
cp -r dist/codex-plugin ~/.codex/plugins/my-plugin

# 方法二：配置 marketplace.json
# 在 ~/.agents/plugins/marketplace.json 或项目级 marketplace.json 中添加：
# { "plugins": [{ "name": "my-plugin", "source": { "path": "./dist/codex-plugin" } }] }

# 方法三：在 Codex 中浏览和安装
# 使用 /plugins 命令查看可用插件
```

### 8.8 推荐的跨平台开发工作流

```
1. 在 shared/ 中编写通用的 Skills、MCP 配置和脚本
2. 在 claude/ 中添加 Claude 专有组件（agents、hooks、LSP）
3. 在 codex/ 中添加 Codex 专有组件（.app.json）
4. 运行 build.sh 生成两个平台的最终插件
5. 分别用 claude --plugin-dir 和 Codex 本地加载测试
6. 用 CI/CD 自动化构建流程，确保两端保持同步
```

---

## 九、最佳实践

1. **从 Skill 开始**：它是最简单、最常用的组件，先做好一个 Skill 再逐步加入 Agent、Hook、MCP
2. **描述要"积极"**：Skill 的 description 决定了触发率，写得"推"一点（列举多种触发场景），避免只写功能描述
3. **保持 SKILL.md 精简**：核心指令控制在 500 行以内，大量参考材料放到 `references/` 子目录
4. **解释"为什么"**：与其写一堆 MUST/NEVER，不如解释背后的原因，让模型理解意图
5. **善用 `${CLAUDE_PLUGIN_DATA}`**：需要持久化的数据（缓存、配置）放在这里，插件更新不会丢失
6. **开发时用 `--plugin-dir`**：避免反复安装/卸载，修改后 `/reload-plugins` 即可
7. **为跨平台做准备**：把核心逻辑放在 `core/`，用适配层对接不同平台

---

## 十、参考资源

### Claude Code

- [Claude Code 插件文档](https://code.claude.com/docs/en/plugins.md)
- [插件技术参考](https://code.claude.com/docs/en/plugins-reference.md)
- [Skills 开发指南](https://code.claude.com/docs/en/skills.md)
- [MCP 配置文档](https://code.claude.com/docs/en/mcp.md)
- [Hooks 指南](https://code.claude.com/docs/en/hooks-guide.md)
- [子代理文档](https://code.claude.com/docs/en/sub-agents.md)
- [插件市场](https://code.claude.com/docs/en/plugin-marketplaces.md)

### OpenAI Codex

- [Codex 插件文档](https://developers.openai.com/codex/plugins)
- [Codex Skills 文档](https://developers.openai.com/codex/skills)
- [Codex MCP 配置](https://developers.openai.com/codex/mcp)
- [Codex Agents SDK 集成](https://developers.openai.com/codex/guides/agents-sdk)
- [Codex App Server](https://developers.openai.com/codex/app-server)
- [Codex 更新日志](https://developers.openai.com/codex/changelog)
- [Codex GitHub 仓库](https://github.com/openai/codex)

### 通用

- [MCP 开放协议](https://modelcontextprotocol.io)
- [OpenAI Skills 仓库（社区）](https://github.com/openai/skills)
