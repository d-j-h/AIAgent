#!/usr/bin/env bash
#
# install-steering.sh
# Utility to link or copy steering files to target workspaces or global agent configurations.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STEERING_DIR="${SCRIPT_DIR}/steering"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"

usage() {
  cat << 'HELP'
Usage: install-steering.sh [OPTIONS] [TARGET_DIR]

Options:
  -m, --mode <symlink|copy>   Installation mode (default: symlink)
  -t, --type <kiro|general|all> Target format (default: all)
  -g, --global                Install into user global directory (~/.kiro/steering)
  -h, --help                  Show this help message

Examples:
  # Symlink all core steering files into current workspace:
  ./scripts/install-steering.sh .

  # Copy Kiro steering templates into a project:
  ./scripts/install-steering.sh --mode copy --type kiro /path/to/project

  # Symlink core steering files into global Kiro directory:
  ./scripts/install-steering.sh --global
HELP
  exit 1
}

MODE="symlink"
TYPE="all"
GLOBAL=false
TARGET_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--mode)
      MODE="$2"
      shift 2
      ;;
    -t|--type)
      TYPE="$2"
      shift 2
      ;;
    -g|--global)
      GLOBAL=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      if [[ -z "$TARGET_DIR" ]]; then
        TARGET_DIR="$1"
        shift
      else
        echo "Error: Unknown option $1"
        usage
      fi
      ;;
  esac
done

if [[ "$GLOBAL" == true ]]; then
  DEST_DIR="${HOME}/.kiro/steering"
else
  if [[ -z "$TARGET_DIR" ]]; then
    TARGET_DIR="."
  fi
  TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
  DEST_DIR="${TARGET_DIR}/.kiro/steering"
fi

mkdir -p "$DEST_DIR"
echo "==> Target steering directory: $DEST_DIR"
echo "==> Mode: $MODE | Type: $TYPE"

install_file() {
  local src="$1"
  local dest="$2"
  if [[ "$MODE" == "symlink" ]]; then
    ln -sfn "$src" "$dest"
    echo "  [Linked] $dest -> $src"
  else
    cp -f "$src" "$dest"
    echo "  [Copied] $dest"
  fi
}

# Install core steering files
for f in "${STEERING_DIR}"/*.md; do
  [[ -e "$f" ]] || continue
  fname="$(basename "$f")"
  install_file "$f" "${DEST_DIR}/${fname}"
done

# If workspace and type is general or all, copy AGENTS.md / GEMINI.md to project root
if [[ "$GLOBAL" == false ]] && [[ "$TYPE" == "general" || "$TYPE" == "all" ]]; then
  if [[ -f "${TEMPLATES_DIR}/general/AGENTS.md" && ! -f "${TARGET_DIR}/AGENTS.md" ]]; then
    install_file "${TEMPLATES_DIR}/general/AGENTS.md" "${TARGET_DIR}/AGENTS.md"
  fi
  if [[ -f "${TEMPLATES_DIR}/general/GEMINI.md" && ! -f "${TARGET_DIR}/GEMINI.md" ]]; then
    install_file "${TEMPLATES_DIR}/general/GEMINI.md" "${TARGET_DIR}/GEMINI.md"
  fi
fi

echo "==> Steering configuration complete!"
