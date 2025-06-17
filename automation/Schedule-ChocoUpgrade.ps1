# automation
# Schedule-ChocoUpgrade.ps1
# This script creates a scheduled task to run 'choco upgrade all' regularly.

Write-Host "🍫 " -ForegroundColor Magenta -NoNewline
Write-Host "Chocolatey Auto-Upgrade Task Scheduler" -ForegroundColor Cyan -BackgroundColor DarkBlue
Write-Host "════════════════════════════════════════" -ForegroundColor DarkCyan

#region Task Configuration Variables
Write-Host "⚙️  Configuring task parameters..." -ForegroundColor Yellow

$TaskName = "Chocolatey Auto Upgrade"
$TaskDescription = "Automatically upgrades all Chocolatey packages weekly."

# Path to the PowerShell 7 executable (pwsh.exe)
Write-Host "🔍 Searching for PowerShell 7 executable..." -ForegroundColor Cyan

$pwshPath = (Get-Command pwsh.exe -ErrorAction SilentlyContinue).Source
if (-not $pwshPath) {
    Write-Host "❌ " -ForegroundColor Red -NoNewline
    Write-Error "PowerShell 7 (pwsh.exe) not found. Cannot schedule Chocolatey upgrade."
    exit 1
}

Write-Host "✅ Found PowerShell 7 at: " -ForegroundColor Green -NoNewline
Write-Host "$pwshPath" -ForegroundColor White

# Set up paths
$chocoPath = if ($env:ChocolateyInstall) { "$env:ChocolateyInstall\bin\choco.exe" } else { "C:\ProgramData\chocolatey\bin\choco.exe" }
$logPath = if ($env:ChocolateyInstall) { "$env:ChocolateyInstall\logs\Chocolatey-AutoUpgrade.log" } else { "C:\ProgramData\chocolatey\logs\Chocolatey-AutoUpgrade.log" }

# Verify Chocolatey exists
if (-not (Test-Path $chocoPath)) {
    Write-Host "❌ " -ForegroundColor Red -NoNewline
    Write-Error "Chocolatey executable not found at: $chocoPath"
    exit 1
}

Write-Host "✅ Found Chocolatey at: " -ForegroundColor Green -NoNewline
Write-Host "$chocoPath" -ForegroundColor White

# Create log directory if it doesn't exist
$logDir = Split-Path -Parent $logPath
if (-not (Test-Path $logDir)) {
    Write-Host "📁 Creating log directory: $logDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$ActionArguments = "-NoProfile -ExecutionPolicy Bypass -Command `"& '$chocoPath' upgrade all --yes --confirm --accept-license --limit-output --log-file '$logPath'`""

Write-Host "📅 Setting up weekly schedule..." -ForegroundColor Magenta

# Trigger: Run weekly on Saturday at 3:00 AM
try {
    $Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Saturday -At "3:00AM"
    Write-Host "✅ Trigger created successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ " -ForegroundColor Red -NoNewline
    Write-Error "Failed to create trigger: $_"
    exit 1
}

Write-Host "🔧 Configuring task settings..." -ForegroundColor Yellow

# Settings: Run even if user is not logged on, with highest privileges
# Fixed: Removed the invalid -StopOnBatteries parameter
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 4)
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType Service -RunLevel Highest

Write-Host "🛡️  Task will run as SYSTEM with highest privileges" -ForegroundColor Green
Write-Host "⏰ Execution time limit: 4 hours" -ForegroundColor Cyan

#endregion

#region Create or Update Scheduled Task
Write-Host ""
Write-Host "🔄 Creating/Updating Scheduled Task" -ForegroundColor Yellow -BackgroundColor DarkMagenta
Write-Host "═══════════════════════════════════" -ForegroundColor DarkCyan

Write-Host "🔍 Checking for existing scheduled task '$TaskName'..." -ForegroundColor Yellow

# Check if task already exists and remove if so (for idempotency)
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Write-Host "⚠️  " -ForegroundColor Yellow -NoNewline
    Write-Warning "Scheduled task '$TaskName' already exists. Updating it."
    Write-Host "🗑️  Removing existing task..." -ForegroundColor Red
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "✅ Old task removed successfully" -ForegroundColor Green
}
else {
    Write-Host "✨ No existing task found - creating new one" -ForegroundColor Green
}

Write-Host "🔨 Building task action..." -ForegroundColor Cyan
# Create the action
$TaskAction = New-ScheduledTaskAction -Execute $pwshPath -Argument $ActionArguments

try {
    Write-Host "📝 Registering scheduled task..." -ForegroundColor Yellow
    
    # Register the scheduled task
    $registeredTask = Register-ScheduledTask -TaskName $TaskName -Description $TaskDescription -Action $TaskAction -Trigger $Trigger -Settings $Settings -Principal $Principal
    
    if ($registeredTask) {
        Write-Host ""
        Write-Host "🎉 SUCCESS! " -ForegroundColor Green -BackgroundColor DarkGreen -NoNewline
        Write-Host " Scheduled task '$TaskName' created/updated successfully." -ForegroundColor Green
        
        # Get the task details to display schedule info safely
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($task) {
            $taskTrigger = $task.Triggers[0]
            if ($taskTrigger) {
                Write-Host "📅 Schedule: " -ForegroundColor Cyan -NoNewline
                Write-Host "Weekly on Saturday at 3:00 AM" -ForegroundColor White
            }
        }
        
        Write-Host "📋 Log File: " -ForegroundColor Cyan -NoNewline
        Write-Host "$logPath" -ForegroundColor White
        
        Write-Host ""
        Write-Host "💡 Pro Tips:" -ForegroundColor Yellow
        Write-Host "   • Check the log file after upgrades to see what was updated" -ForegroundColor Gray
        Write-Host "   • You can manually run the task from Task Scheduler if needed" -ForegroundColor Gray
        Write-Host "   • Task runs as SYSTEM so it won't require user interaction" -ForegroundColor Gray
        
        Write-Host ""
        Write-Host "🍫✨ Your Chocolatey packages will now stay fresh automatically! ✨🍫" -ForegroundColor Magenta
    }
    else {
        throw "Task registration returned null"
    }
}
catch {
    Write-Host ""
    Write-Host "❌ FAILED! " -ForegroundColor Red -BackgroundColor DarkRed -NoNewline
    Write-Error "Failed to create scheduled task '$TaskName': $_"
    Write-Host "🔐 " -ForegroundColor Yellow -NoNewline
    Write-Host "Ensure you are running PowerShell as Administrator." -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "   • Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Gray
    Write-Host "   • Ensure Task Scheduler service is running" -ForegroundColor Gray
    Write-Host "   • Check if Group Policy restrictions are blocking task creation" -ForegroundColor Gray
    Write-Host "   • Try running: Get-Service Schedule | Start-Service" -ForegroundColor Gray
}
#endregion

Write-Host ""
Write-Host "════════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host "🏁 Script execution completed" -ForegroundColor Cyan