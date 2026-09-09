# AIAgent: Steering Files & AI Coding Guidelines

A centralized, version-controlled repository to manage and track **steering files**, guidelines, and configuration templates for AI coding agents (such as Kiro, Google Antigravity, Gemini CLI, Cursor, and Claude Code).

* **Repository**: [https://github.com/d-j-h/AIAgent](https://github.com/d-j-h/AIAgent)
* **Default Branch**: `main`

---

## 🎯 What are Steering Files?

Steering files are markdown documents that provide persistent, project-specific or global context to AI coding agents. Instead of repeating instructions, tech stacks, and conventions in every prompt, steering files define:

* **Core Principles & Non-Negotiables**: Guardrails on verification, safety, and testing.
* **Code Standards & Patterns**: Language idioms, typing standards, error handling, and commit conventions.
* **Behavior & Workflow**: How the agent plans, navigates ambiguities, and modifies code surgically.
* **Project Specifications**: Product vision, tech stack boundaries, and directory conventions.

---

## 📂 Repository Structure

```text
~/git/AIAgent/
├── .gitignore                      # Ignore temporary and editor artifacts
├── README.md                       # Documentation & usage guide
├── steering/                       # Universal core steering files
│   ├── core-principles.md          # Fundamental rules and safety guidelines
│   ├── code-standards.md           # Typing, linting, error handling, commits
│   ├── agent-behavior.md           # Planning, execution discipline, communication
│   └── architecture-and-security.md# Architecture patterns and security rules
├── templates/                      # Agent-specific starter templates
│   ├── kiro/                       # Kiro specification templates
│   │   ├── tech.md                 # Tech stack and build constraints
│   │   ├── structure.md            # Repository file organization
│   │   └── product.md              # High-level product overview
│   └── general/                    # Universal rule files
│       ├── AGENTS.md               # Hierarchical agent rules
│       └── GEMINI.md               # Gemini / Antigravity workspace rules
└── scripts/                        # Automation & integration scripts
    └── install-steering.sh         # Helper to link/copy files into workspaces
```

---

## 🚀 How to Use & Apply Steering Files

### 1. Inclusion Modes (Frontmatter)
Steering files use YAML frontmatter to control when they are loaded into the agent's context window:
* **`inclusion: always`**: Loaded into every agent interaction (ideal for core standards).
* **`inclusion: fileMatch`**: Loaded dynamically when editing files matching specific patterns.
* **`inclusion: manual`**: Loaded only when explicitly referenced by name.

### 2. Workspace-Level Steering
To apply steering files to a specific project workspace:

```bash
# Symlink core steering files into your project's .kiro/steering directory:
./scripts/install-steering.sh /path/to/my-project

# Or copy instead of symlinking:
./scripts/install-steering.sh --mode copy /path/to/my-project
```

### 3. Global Steering
To make these steering rules apply across all projects on your machine:

```bash
# Symlink core steering files to ~/.kiro/steering:
./scripts/install-steering.sh --global
```

---

## 🔗 Local & Remote Synchronization

To sync this repository across machines (e.g. on your local laptop):

```bash
cd ~/git
git clone git@github.com:d-j-h/AIAgent.git
```
