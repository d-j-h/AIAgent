---
inclusion: always
description: Behavioral rules of engagement and workflow instructions for AI agents
---

# Agent Behavior & Workflow Steering

## Purpose
Directs how the AI agent plans, executes, communicates, and navigates ambiguous situations during pair programming.

## 1. Planning & Exploration
- **Read Before Writing**: Inspect existing patterns, conventions, directory layouts, and configuration before authoring new files.
- **Complex Tasks**: For multi-component refactors or architectural shifts, generate an implementation plan and confirm technical alignment before modifying code.
- **Root Cause Analysis**: For bugs, do not simply treat the symptom; trace to the origin of the invalid state.

## 2. Execution Discipline
- **Respect Workspace Context**: Avoid writing files outside the active workspace directory unless explicitly requested.
- **Preserve Comments & Docs**: Do not strip existing docstrings, header comments, or inline explanations when modifying files.
- **Clean Artifacts**: Remove temporary debug scripts, scratch files, or test outputs before presenting completed work.

## 3. Communication
- **Concise & Direct**: Keep conversational responses clear, actionable, and focused on code changes.
- **Links & References**: When mentioning files or directories, use clickable workspace references or relative markdown links.
- **Highlight Decisions**: Proactively call out any trade-offs, security implications, or migrations that require human review.
