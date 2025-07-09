#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
#  🎨 Git Hooks Setup Script
#  ─────────────────────────────────────────────────────────────────────────────

# Color definitions
RESET="\033[0m"
BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RED="\033[31m"

# Directories
DOTFILES_DIR="$HOME/.dotfiles"
HOOKS_SOURCE_DIR="$DOTFILES_DIR/linux/git-hooks"
HOOKS_TARGET_DIR="$HOME/.git_hooks"

# ─────────────────────────────────────────────────────────────────────────────
#  🛠️  Functions
# ─────────────────────────────────────────────────────────────────────────────

info() {
  printf "${CYAN}%s${RESET}\n" "➜ $*"
}

success() {
  printf "${GREEN}%s${RESET}\n" "✔ $*"
}

warning() {
  printf "${YELLOW}%s${RESET}\n" "⚠ $*"
}

error() {
  printf "${RED}%s${RESET}\n" "✖ $*" >&2
  exit 1
}

# ─────────────────────────────────────────────────────────────────────────────
#  🔍 Pre-flight Checks
# ─────────────────────────────────────────────────────────────────────────────

[ -d "$HOOKS_SOURCE_DIR" ] || error "Hooks source directory not found: $HOOKS_SOURCE_DIR"
info "Found hooks in $HOOKS_SOURCE_DIR"

# ─────────────────────────────────────────────────────────────────────────────
#  📂 Create Target Directory
# ─────────────────────────────────────────────────────────────────────────────

info "Ensuring hooks directory exists at $HOOKS_TARGET_DIR..."
mkdir -p "$HOOKS_TARGET_DIR"
success "Directory ready: $HOOKS_TARGET_DIR"

# ─────────────────────────────────────────────────────────────────────────────
#  🧹 Clean Existing Hooks
# ─────────────────────────────────────────────────────────────────────────────

if compgen -G "$HOOKS_TARGET_DIR/*" > /dev/null; then
  warning "Removing existing hooks in $HOOKS_TARGET_DIR..."
  rm -f "$HOOKS_TARGET_DIR"/*
  success "Old hooks cleared"
else
  info "No existing hooks to remove"
fi

# ─────────────────────────────────────────────────────────────────────────────
#  🔗 Symlink and Make Executable
# ─────────────────────────────────────────────────────────────────────────────

info "Linking new hooks..."
for src in "$HOOKS_SOURCE_DIR"/*; do
  name="$(basename "$src")"
  target="$HOOKS_TARGET_DIR/$name"

  ln -sf "$src" "$target"
  chmod +x "$target"

  success "Linked & made executable: $name"
done

# ─────────────────────────────────────────────────────────────────────────────
#  ⚙️  Configure Git
# ─────────────────────────────────────────────────────────────────────────────

info "Setting Git core.hooksPath to $HOOKS_TARGET_DIR..."
git config --global core.hooksPath "$HOOKS_TARGET_DIR"
success "Git hooksPath configured"

# ─────────────────────────────────────────────────────────────────────────────
#  🎉 Done!
# ─────────────────────────────────────────────────────────────────────────────

printf "\n${BOLD}${GREEN}Git hooks setup complete!${RESET}\n"
