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
        Write-Host "🍫 Chocolatey is not found. Installing Chocolatey..." -ForegroundColor Yellow

        # Set execution policy to Bypass for the current process temporarily
        $originalExecutionPolicy = Get-ExecutionPolicy -Scope Process
        Set-ExecutionPolicy Bypass -Scope Process -Force

        try {
            # Official Chocolatey install command
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            Write-Host "✅ Chocolatey installed successfully!" -ForegroundColor Green
        }
        catch {
            Write-Host "❌ Failed to install Chocolatey: $($_.Exception.Message)" -ForegroundColor Red
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
        Write-Host "✅ Chocolatey is already installed." -ForegroundColor Cyan
    }
}

Install-Chocolatey

# Give Chocolatey a moment to register, and confirm it's available
if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Chocolatey command not found after installation attempt. Please close and re-open PowerShell as Administrator and run the script again." -ForegroundColor Red
    exit 1
}
#endregion

#region Enable Chocolatey Global Confirmation for Automation
Write-Host "🔧 Configuring Chocolatey for automation..." -ForegroundColor Cyan
try {
    # Enable global confirmation to prevent prompts during automated upgrades
    choco feature enable -n allowGlobalConfirmation -y | Out-Null
    Write-Host "✅ Chocolatey global confirmation enabled for automated operations" -ForegroundColor Green
}
catch {
    Write-Host "⚠️  Could not enable Chocolatey global confirmation: $($_.Exception.Message)" -ForegroundColor Yellow
}
#endregion

Write-Host "--- Initial Setup Complete (Chocolatey is ready!) ---" -ForegroundColor Green

Write-Host "🚀 Chocolatey is ready! Proceeding with package installation..." -ForegroundColor Green

#region Install Chocolatey packages from packages.config
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition # Get the directory of the current script
$packagesConfigPath = Join-Path $scriptDir "applications\chocolatey\packages.config"

if (Test-Path $packagesConfigPath) {
    Write-Host "📦 Installing/Upgrading Chocolatey packages from $($packagesConfigPath)..." -ForegroundColor Yellow
    try {
        # Use choco install with --yes to accept prompts and --config to specify the config file
        # Use --no-progress to suppress the progress bar for cleaner output in scripts
        choco install $packagesConfigPath --yes --no-progress --skip-if-not-installed 2>&1 | Where-Object {
            $_ -notmatch "already installed" -and 
            $_ -notmatch "Use --force to reinstall"
        } | ForEach-Object { Write-Host $_ }
        Write-Host "✅ Chocolatey packages installation/upgrade complete!" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to install Chocolatey packages: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "⚠️  packages.config not found at '$packagesConfigPath'. Skipping Chocolatey package installation." -ForegroundColor Yellow
}
#endregion

#region Install Windows Terminal separately
Write-Host "🖥️ Checking Windows Terminal installation..." -ForegroundColor Cyan

# Check if Windows Terminal is already installed
if (Get-Command wt -ErrorAction SilentlyContinue) {
    Write-Host "✅ Windows Terminal is already installed" -ForegroundColor Green
} else {
    Write-Host "📦 Installing Windows Terminal via winget..." -ForegroundColor Yellow
    try {
        # Check if winget is available
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget install --id Microsoft.WindowsTerminal -e --accept-source-agreements --accept-package-agreements
            Write-Host "✅ Windows Terminal installed successfully via winget!" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Winget not found. Please install Windows Terminal manually from the Microsoft Store." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "❌ Could not install Windows Terminal automatically." -ForegroundColor Red
        Write-Host "   Please install it manually from the Microsoft Store." -ForegroundColor Gray
    }
}
#endregion

#region Refresh environment variables
Write-Host "🔄 Refreshing environment variables..." -ForegroundColor Cyan
try {
    refreshenv
    Write-Host "✅ Environment variables refreshed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "⚠️  Could not refresh environment variables automatically. You may need to restart your terminal." -ForegroundColor Yellow
}
#endregion

#region Verify critical packages
Write-Host "🔍 Verifying critical package installations..." -ForegroundColor Cyan
$criticalPackages = @("git", "vscode", "powershell-core", "googlechrome", "7zip")
$failedPackages = @()

# Get all installed packages at once (more efficient)
$installedPackages = choco list --limit-output | ForEach-Object {
    $parts = $_ -split '\|'
    if ($parts.Count -ge 2) {
        $parts[0].ToLower()
    }
}

foreach ($pkg in $criticalPackages) {
    if ($installedPackages -contains $pkg.ToLower()) {
        Write-Host "  ✅ $pkg - installed" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $pkg - not found" -ForegroundColor Red
        $failedPackages += $pkg
    }
}

if ($failedPackages.Count -gt 0) {
    Write-Host "⚠️  Some critical packages may not have installed correctly: $($failedPackages -join ', ')" -ForegroundColor Yellow
    Write-Host "   You may want to manually install these packages later." -ForegroundColor Gray
} else {
    Write-Host "✅ All critical packages verified successfully!" -ForegroundColor Green
}
#endregion

Write-Host "--- Initial Software Installation Complete ---" -ForegroundColor Green

Write-Host "⚙️  Applying PowerShell Profile Configurations..." -ForegroundColor Green

#region Set up User Profile specific configurations (e.g., PowerShell Profile)
$powerShellProfileSource = Join-Path $scriptDir "user-profile\Microsoft.PowerShell_profile.ps1"
$powerShellProfileTarget = $PROFILE # $PROFILE is a built-in PowerShell variable for the profile path

if (Test-Path $powerShellProfileSource) {
    Write-Host "📝 Setting up PowerShell profile..." -ForegroundColor Yellow
    # Ensure the target directory exists
    $profileDir = Split-Path -Parent $powerShellProfileTarget
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        Write-Host "  📁 Created profile directory: $profileDir" -ForegroundColor Gray
    }

    # Copy the profile file. Using Copy-Item is generally simpler and safer than symlinks for profiles.
    Copy-Item -Path $powerShellProfileSource -Destination $powerShellProfileTarget -Force -Confirm:$false
    Write-Host "✅ PowerShell profile setup complete. Restart PowerShell to see changes." -ForegroundColor Green
} else {
    Write-Host "⚠️  PowerShell profile source not found at '$powerShellProfileSource'. Skipping profile setup." -ForegroundColor Yellow
}
#endregion

#region Configure Git Global Settings
Write-Host "🔧 Configuring Git Global Settings..." -ForegroundColor Green

try {
    # Check if git is available
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "⚠️  Git is not installed or not in PATH. Skipping Git configuration." -ForegroundColor Yellow
    } else {
        # Check if user.name is already set globally
        $currentGitUserName = & git config --global user.name 2>$null
        
        if ([string]::IsNullOrWhiteSpace($currentGitUserName)) {
            # If not set, prompt the user for their Git user name
            Write-Host "📝 Git user name not configured." -ForegroundColor Yellow
            $gitUserName = Read-Host -Prompt "Enter your Git user name (e.g., 'John Doe')"
            if (![string]::IsNullOrWhiteSpace($gitUserName)) {
                & git config --global user.name "$gitUserName"
                Write-Host "✅ Git global user.name set to '$gitUserName'." -ForegroundColor Green
            } else {
                Write-Host "⚠️  Git user name not provided. Skipping setting user.name." -ForegroundColor Yellow
            }
        } else {
            Write-Host "✅ Git global user.name is already set to '$currentGitUserName'." -ForegroundColor Cyan
        }

        # Check if user.email is already set globally
        $currentGitUserEmail = & git config --global user.email 2>$null
        
        if ([string]::IsNullOrWhiteSpace($currentGitUserEmail)) {
            # If not set, prompt the user for their Git user email
            Write-Host "📝 Git user email not configured." -ForegroundColor Yellow
            $gitUserEmail = Read-Host -Prompt "Enter your Git user email (e.g., 'your.email@example.com')"
            if (![string]::IsNullOrWhiteSpace($gitUserEmail)) {
                & git config --global user.email "$gitUserEmail"
                Write-Host "✅ Git global user.email set to '$gitUserEmail'." -ForegroundColor Green
            } else {
                Write-Host "⚠️  Git user email not provided. Skipping setting user.email." -ForegroundColor Yellow
            }
        } else {
            Write-Host "✅ Git global user.email is already set to '$currentGitUserEmail'." -ForegroundColor Cyan
        }

        Write-Host "✅ Git global settings configuration complete." -ForegroundColor Green
    }
}
catch {
    Write-Host "❌ Failed to configure Git global settings: $($_.Exception.Message)" -ForegroundColor Red
}
#endregion

#region Setup Chocolatey Auto-Upgrade Scheduler
Write-Host ""
Write-Host "🤖 Setting up Chocolatey Auto-Upgrade Automation..." -ForegroundColor Green

$chocoSchedulerPath = Join-Path $scriptDir "automation\Schedule-ChocoUpgrade.ps1"

if (Test-Path $chocoSchedulerPath) {
    Write-Host "📅 Configuring automatic Chocolatey upgrades..." -ForegroundColor Yellow
    try {
        # Execute the scheduler script
        & $chocoSchedulerPath
        Write-Host "✅ Chocolatey auto-upgrade scheduler configured successfully!" -ForegroundColor Green
        Write-Host "   📋 Your packages will be automatically updated weekly on Saturdays at 3:00 AM" -ForegroundColor Cyan
    }
    catch {
        Write-Host "⚠️  Failed to setup Chocolatey auto-upgrade scheduler: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "   💡 You can run the scheduler manually later: .\automation\Schedule-ChocoUpgrade.ps1" -ForegroundColor Gray
    }
} else {
    Write-Host "⚠️  Chocolatey scheduler script not found at '$chocoSchedulerPath'" -ForegroundColor Yellow
    Write-Host "   💡 Make sure the automation\Schedule-ChocoUpgrade.ps1 file exists" -ForegroundColor Gray
}
#endregion

#region Check for package updates
Write-Host "🔄 Checking for package updates..." -ForegroundColor Cyan
try {
    # Just use 'choco outdated' without additional parameters
    $outdatedPackages = choco outdated --limit-output | Where-Object { $_ -and $_ -notmatch '^Chocolatey' }
    
    if ($outdatedPackages) {
        $outdatedCount = ($outdatedPackages | Measure-Object).Count
        Write-Host "📦 Found $outdatedCount outdated package(s):" -ForegroundColor Yellow
        $outdatedPackages | ForEach-Object {
            $parts = $_ -split '\|'
            if ($parts.Length -ge 3) {
                $packageName = $parts[0]
                $currentVersion = $parts[1]
                $availableVersion = $parts[2]
                Write-Host "  🔄 $packageName ($currentVersion → $availableVersion)" -ForegroundColor Gray
            }
        }
        Write-Host "💡 Run 'choco upgrade all' later to update these packages." -ForegroundColor Magenta
    } else {
        Write-Host "✅ All packages are up to date!" -ForegroundColor Green
    }
}
catch {
    Write-Host "⚠️  Could not check for package updates: $($_.Exception.Message)" -ForegroundColor Yellow
}
#endregion

Write-Host ""
Write-Host "🎉 Windows Dotfiles Setup Complete!" -ForegroundColor Green
Write-Host "💡 Next steps:" -ForegroundColor Magenta
Write-Host "   • Restart your PowerShell to load the new profile" -ForegroundColor Gray
Write-Host "   • Configure Windows Terminal with your preferred settings" -ForegroundColor Gray
Write-Host "   • Run 'choco upgrade all' periodically to keep packages updated" -ForegroundColor Gray
Write-Host ""