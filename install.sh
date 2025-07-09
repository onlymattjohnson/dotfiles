#!/bin/bash
#
# Top-level installer script to detect the OS and delegate to the
# appropriate OS-specific installation script.

# --- Functions ---
detect_os() {
  case "$(uname -s)" in
    Linux)
      echo "Linux"
      ;;
    Darwin)
      echo "macOS"
      ;;
    CYGWIN*|MINGW*|MSYS*)
      echo "Windows"
      ;;
    *)
      echo "Unknown"
      ;;
  esac
}

# --- Main Execution ---
main() {
  local os
  os=$(detect_os)
  local script_dir
  script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

  echo "🚀 Bootstrapping dotfiles..."
  echo "Detected Operating System: $os"

  case "$os" in
    Linux|macOS)
      echo "-> Running the Unix installer..."
      # shellcheck source=./linux/install.sh
      source "$script_dir/linux/install.sh"
      ;;
    Windows)
      echo "-> Windows detected."
      echo "Please run the 'install.ps1' script from within the 'windows' directory using PowerShell."
      ;;
    *)
      echo "-> Unsupported operating system."
      echo "No installation script found for '$os'."
      exit 1
      ;;
  esac

  echo "✅ Dotfiles bootstrap complete."
}

main "$@"
