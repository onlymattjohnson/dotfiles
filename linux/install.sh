#!/bin/bash

echo "-> Setting up Git hooks..."

# This script assumes the dotfiles repository is located at ~/.dotfiles
# This is a common convention for dotfiles repositories.
DOTFILES_DIR="$HOME/.dotfiles"
HOOKS_SOURCE_DIR="$DOTFILES_DIR/linux/git-hooks"
HOOKS_TARGET_DIR="$HOME/.git_hooks"

# Create the target directory for git hooks
echo "   Creating hooks directory at $HOOKS_TARGET_DIR..."
mkdir -p "$HOOKS_TARGET_DIR"

# Symlink all hooks from the dotfiles repo to the target directory.
# The -f flag ensures that we overwrite any existing symlinks if the script is re-run.
echo "   Symlinking hooks from $HOOKS_SOURCE_DIR to $HOOKS_TARGET_DIR..."
ln -sf "$HOOKS_SOURCE_DIR"/* "$HOOKS_TARGET_DIR"/

# Configure git to use the new hooks directory globally.
echo "   Configuring git core.hooksPath to $HOOKS_TARGET_DIR..."
git config --global core.hooksPath "$HOOKS_TARGET_DIR"

echo "   Git hooks setup complete."
