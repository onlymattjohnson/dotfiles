# setup.ps1
# This is your main setup script for your Windows machine.
# It's designed to be run on a new machine to quickly get it configured.

#region Function to ensure Administrator Privileges
function Test-IsAdministrator {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdministrator)) {
    Write-Host "This script needs to be run as Administrator. Restarting..." -ForegroundColor Yellow
    Start-Process PowerShell -Verb RunAs -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`""
    exit
}
#endregion

Write-Host "--- Starting Windows Dotfiles Setup ---" -ForegroundColor Green

#region Install Chocolatey if not present
function Install-Chocolatey {
    if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
        Write-Host "Chocolatey is not found. Installing Chocolatey..." -ForegroundColor Yellow

        # Set execution policy to Bypass for the current process temporarily
        $originalExecutionPolicy = Get-ExecutionPolicy -Scope Process
        Set-ExecutionPolicy Bypass -Scope Process -Force

        try {
            # Official Chocolatey install command
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            Write-Host "Chocolatey installed successfully!" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to install Chocolatey: $($_.Exception.Message)"
            exit 1 # Exit with an error code
        }
        finally {
            # Revert execution policy for the current process
            Set-ExecutionPolicy $originalExecutionPolicy -Scope Process -Force
        }

        # Ensure choco is available in the current session's path
        # Sometimes a new shell is needed, but this helps.
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        $env:Path = $env:Path + ";$($env:ChocolateyInstall)\bin"
    } else {
        Write-Host "Chocolatey is already installed." -ForegroundColor Cyan
    }
}

Install-Chocolatey

# Give Chocolatey a moment to register, and confirm it's available
if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey command not found after installation attempt. Please close and re-open PowerShell as Administrator and run the script again." -ForegroundColor Red
    exit 1
}
#endregion

Write-Host "--- Initial Setup Complete (Chocolatey is ready!) ---" -ForegroundColor Green

# ... (previous content of setup.ps1) ...

Write-Host "--- Chocolatey is ready! Proceeding with package installation ---" -ForegroundColor Green

#region Install Chocolatey packages from packages.config
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition # Get the directory of the current script
$packagesConfigPath = Join-Path $scriptDir "applications\chocolatey\packages.config"

if (Test-Path $packagesConfigPath) {
    Write-Host "Installing/Upgrading Chocolatey packages from $($packagesConfigPath)..." -ForegroundColor Yellow
    try {
        # Use choco install with --yes to accept prompts and --config to specify the config file
        # Use --no-progress to suppress the progress bar for cleaner output in scripts
        choco install $packagesConfigPath --yes --no-progress
        Write-Host "Chocolatey packages installation/upgrade complete!" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install Chocolatey packages: $($_.Exception.Message)"
    }
} else {
    Write-Warning "packages.config not found at '$packagesConfigPath'. Skipping Chocolatey package installation."
}
#endregion

Write-Host "--- Initial Software Installation Complete ---" -ForegroundColor Green

Write-Host "--- Applying PowerShell Profile Configurations ---" -ForegroundColor Green

#region Set up User Profile specific configurations (e.g., PowerShell Profile)
$powerShellProfileSource = Join-Path $scriptDir "user-profile\Microsoft.PowerShell_profile.ps1"
$powerShellProfileTarget = $PROFILE # $PROFILE is a built-in PowerShell variable for the profile path

if (Test-Path $powerShellProfileSource) {
    Write-Host "Setting up PowerShell profile..." -ForegroundColor Yellow
    # Ensure the target directory exists
    $profileDir = Split-Path -Parent $powerShellProfileTarget
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }

    # Copy the profile file. Using Copy-Item is generally simpler and safer than symlinks for profiles.
    Copy-Item -Path $powerShellProfileSource -Destination $powerShellProfileTarget -Force -Confirm:$false
    Write-Host "PowerShell profile setup complete. Restart PowerShell to see changes." -ForegroundColor Green
} else {
    Write-Warning "PowerShell profile source not found at '$powerShellProfileSource'. Skipping profile setup."
}
#endregion

Write-Host "--- Configuring Git Global Settings ---" -ForegroundColor Green

#region Configure Git Global Settings
try {
    # Check if user.name is already set globally
    $currentGitUserName = git config --global user.name -ErrorAction SilentlyContinue # Use -ErrorAction SilentlyContinue to suppress errors if not set
    if ($null -eq $currentGitUserName -or $currentGitUserName -eq "") {
        # If not set, prompt the user for their Git user name
        $gitUserName = Read-Host -Prompt "Enter your Git user name (e.g., 'John Doe')"
        if ($gitUserName) { # Only set if user provides a value
            git config --global user.name "$gitUserName"
            Write-Host "Git global user.name set to '$gitUserName'." -ForegroundColor Green
        } else {
            Write-Warning "Git user name not provided. Skipping setting user.name."
        }
    } else {
        Write-Host "Git global user.name is already set to '$currentGitUserName'." -ForegroundColor Cyan
    }

    # Check if user.email is already set globally
    $currentGitUserEmail = git config --global user.email -ErrorAction SilentlyContinue # Use -ErrorAction SilentlyContinue
    if ($null -eq $currentGitUserEmail -or $currentGitUserEmail -eq "") {
        # If not set, prompt the user for their Git user email
        $gitUserEmail = Read-Host -Prompt "Enter your Git user email (e.g., 'your.email@example.com')"
        if ($gitUserEmail) { # Only set if user provides a value
            git config --global user.email "$gitUserEmail"
            Write-Host "Git global user.email set to '$gitUserEmail'." -ForegroundColor Green
        } else {
            Write-Warning "Git user email not provided. Skipping setting user.email."
        }
    } else {
        Write-Host "Git global user.email is already set to '$currentGitUserEmail'." -ForegroundColor Cyan
    }

    Write-Host "Git global settings configuration complete." -ForegroundColor Green
}
catch {
    Write-Error "Failed to configure Git global settings: $($_.Exception.Message)"
}
#endregion

Write-Host "--- Windows Dotfiles Setup Complete! ---" -ForegroundColor Green