# My Windows Dotfiles

This repository contains my personal setup scripts and configuration files for quickly provisioning a new Windows development machine. The goal is to automate the installation of essential tools, customize the PowerShell experience, and apply core system settings, streamlining the setup process.

## ✨ Features

This setup automates the installation and configuration of:

* **Chocolatey:** The package manager for Windows, used for all subsequent software installations.
* **PowerShell 7 (`pwsh`):** The modern, cross-platform version of PowerShell, replacing the default Windows PowerShell 5.1 for daily use.
* **Oh My Posh:** A highly customizable and beautiful prompt for PowerShell, providing rich contextual information (like Git status, current directory, etc.).
* **posh-git:** Seamless Git integration within your PowerShell prompt.
* **Visual Studio Code:** My preferred code editor, set up for easy synchronization of settings and extensions.
* **Common Utilities:** Essential tools like Google Chrome, 7-Zip, VLC Media Player, Notepad++, and Windows Terminal.
* **Development Runtimes:** Node.js LTS and Python for a broad range of development tasks and tool dependencies.
* **Automated Git Configuration:** Sets up your global Git `user.name` and `user.email` interactively.
* **Custom PowerShell Profile:** Includes common aliases, functions, and initial PSReadLine configurations for an enhanced terminal experience.

## 🚀 Getting Started

Follow these steps to set up a new Windows machine using these dotfiles.

### Prerequisites

Before you begin, ensure your machine has:

* **Windows 10 or 11:** A relatively up-to-date installation. If you are on a very old build, consider using the [Windows Update Assistant (Win10)](https://www.microsoft.com/software-download/windows10) or [Windows 11 Installation Assistant (Win11)](https://www.microsoft.com/software-download/windows11) first.
* **Internet Connection:** Required for downloading software.
* **Administrator Privileges:** The `setup.ps1` script will require Administrator rights to install software and make system changes.
* **Git Installed:** This is the *only* tool you need to install manually to start.
    * Download from: [https://git-scm.com/download/win](https://git-scm.com/download/win)
    * During installation, ensure **"Enable symbolic links"** is checked. If you forget, run `git config --global core.symlinks true` in a regular PowerShell window and enable Windows [Developer Mode](https://learn.microsoft.com/en-us/windows/apps/get-started/developer-mode) in Settings.

### Installation Steps

1.  **Clone this repository:**
    Open a **regular (non-admin) PowerShell** window and navigate to where you want to store your dotfiles (e.g., `C:\Users\YourUser\Documents\`).
    ```powershell
    cd C:\Users\YourUser\Documents\ # Or your preferred location
    git clone [https://github.com/your-username/dotfiles.git](https://github.com/your-username/dotfiles.git)
    cd dotfiles
    ```
    *(Remember to replace `your-username` with your actual GitHub username)*

2.  **Run the main setup script:**
    Open a **new PowerShell window as Administrator**.
    Navigate to your cloned `dotfiles` directory:
    ```powershell
    cd C:\Users\YourUser\Documents\dotfiles
    .\setup.ps1
    ```
    * The script will first ensure Chocolatey is installed.
    * It will then install all applications listed in `applications/chocolatey/packages.config`.
    * **Interactive Prompts:** The script will prompt you to enter your Git `user.name` and `user.email`.
    * Finally, it will apply your PowerShell profile and other configurations.

3.  **Post-Setup Actions:**
    * **Restart Terminal/PowerShell:** Close and reopen all PowerShell/Windows Terminal windows to ensure the new PowerShell 7 environment and Oh My Posh prompt are fully loaded.
    * **Set PowerShell 7 as Default in Windows Terminal:**
        * Open Windows Terminal -> Settings (`Ctrl + ,`).
        * Go to "Startup" -> "Default profile" and select "PowerShell" (the one pointing to `pwsh.exe`).
    * **Enable VS Code Settings Sync:**
        * Open VS Code -> Click the Gear icon (Manage) in the bottom-left -> "Turn on Settings Sync..."
        * Sign in with your GitHub account to synchronize your VS Code settings, extensions, and more.

## ⚙️ Customization

* **`applications/chocolatey/packages.config`:** Add or remove `<package id="your-package-id" />` entries to customize which software is installed. Find package IDs on the [Chocolatey Community Repository](https://community.chocolatey.org/packages).
* **`user-profile/Microsoft.PowerShell_profile.ps1`:** Add your own custom PowerShell aliases, functions, and environment variables to this file to personalize your shell experience.
* **`setup.ps1`:** Extend this main script with more specific system configurations (e.g., registry tweaks, Explorer settings) if desired.

## 🤝 Contribution

Feel free to fork this repository or provide suggestions if you find these dotfiles useful!

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details.