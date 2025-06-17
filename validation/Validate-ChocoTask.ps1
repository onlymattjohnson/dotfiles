# Validate-ChocoTask.ps1
# Script to validate the Chocolatey Auto Upgrade scheduled task

Write-Host "🔍 Chocolatey Auto Upgrade Task Validator" -ForegroundColor Cyan -BackgroundColor DarkBlue
Write-Host "══════════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host ""

$TaskName = "Chocolatey Auto Upgrade"

# 1. Check if task exists
Write-Host "1️⃣  Checking if task exists..." -ForegroundColor Yellow
$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($task) {
    Write-Host "   ✅ Task found!" -ForegroundColor Green
    Write-Host "   📋 Description: $($task.Description)" -ForegroundColor Gray
} else {
    Write-Host "   ❌ Task not found!" -ForegroundColor Red
    exit 1
}

# 2. Check task configuration
Write-Host ""
Write-Host "2️⃣  Checking task configuration..." -ForegroundColor Yellow
$taskInfo = $task | Get-ScheduledTaskInfo
$trigger = $task.Triggers[0]
$action = $task.Actions[0]
$principal = $task.Principal

Write-Host "   👤 Run as: $($principal.UserId)" -ForegroundColor Cyan
Write-Host "   🔐 Run Level: $($principal.RunLevel)" -ForegroundColor Cyan
Write-Host "   📅 Schedule: $($trigger.DaysOfWeek) at $($trigger.StartBoundary.Substring(11,8))" -ForegroundColor Cyan
Write-Host "   🚀 Action: $($action.Execute)" -ForegroundColor Cyan
Write-Host "   📄 Arguments: $($action.Arguments.Substring(0, [Math]::Min(50, $action.Arguments.Length)))..." -ForegroundColor Gray

# 3. Check last run information
Write-Host ""
Write-Host "3️⃣  Checking last run information..." -ForegroundColor Yellow
if ($taskInfo.LastRunTime -eq "1/1/0001 12:00:00 AM") {
    Write-Host "   ⚠️  Task has never run" -ForegroundColor Yellow
} else {
    Write-Host "   ⏰ Last Run: $($taskInfo.LastRunTime)" -ForegroundColor Cyan
    $resultMessages = @{
        0 = "✅ Success"
        1 = "❌ Incorrect function called or unknown function called"
        2 = "❌ File not found"
        10 = "⚠️  Environment incorrect"
        267009 = "✅ Task is currently running"
        267011 = "⚠️  Task has not yet run"
        267014 = "❌ Task was terminated by user"
        2147750687 = "❌ Credentials became corrupted"
    }
    $resultMsg = if ($resultMessages.ContainsKey($taskInfo.LastTaskResult)) { 
        $resultMessages[$taskInfo.LastTaskResult] 
    } else { 
        "❓ Unknown result code: $($taskInfo.LastTaskResult)" 
    }
    Write-Host "   📊 Last Result: $resultMsg" -ForegroundColor $(if ($taskInfo.LastTaskResult -eq 0) { "Green" } else { "Red" })
}
Write-Host "   🔜 Next Run: $($taskInfo.NextRunTime)" -ForegroundColor Cyan

# 4. Test if we can run the task
Write-Host ""
Write-Host "4️⃣  Testing task execution..." -ForegroundColor Yellow
Write-Host "   Would you like to run the task now? (y/n): " -ForegroundColor Magenta -NoNewline
$response = Read-Host

if ($response -eq 'y') {
    Write-Host "   🚀 Starting task..." -ForegroundColor Yellow
    try {
        Start-ScheduledTask -TaskName $TaskName
        Write-Host "   ✅ Task started successfully!" -ForegroundColor Green
        
        # Monitor the task
        Write-Host "   ⏳ Monitoring task execution..." -ForegroundColor Yellow
        $timeout = 300  # 5 minutes timeout
        $elapsed = 0
        while ($elapsed -lt $timeout) {
            Start-Sleep -Seconds 5
            $elapsed += 5
            $currentTask = Get-ScheduledTask -TaskName $TaskName
            $currentInfo = $currentTask | Get-ScheduledTaskInfo
            
            if ($currentTask.State -ne "Running") {
                Write-Host "   ✅ Task completed!" -ForegroundColor Green
                Write-Host "   📊 Result: $(if ($currentInfo.LastTaskResult -eq 0) { '✅ Success' } else { "❌ Failed with code $($currentInfo.LastTaskResult)" })" -ForegroundColor $(if ($currentInfo.LastTaskResult -eq 0) { "Green" } else { "Red" })
                break
            } else {
                Write-Host "   ⏳ Still running... ($elapsed seconds elapsed)" -ForegroundColor Gray
            }
        }
        
        if ($elapsed -ge $timeout) {
            Write-Host "   ⚠️  Task is still running after 5 minutes. Check Task Scheduler for status." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "   ❌ Failed to start task: $_" -ForegroundColor Red
    }
}

# 5. Check log file
Write-Host ""
Write-Host "5️⃣  Checking log file..." -ForegroundColor Yellow
$logPath = if ($env:ChocolateyInstall) { 
    "$env:ChocolateyInstall\logs\Chocolatey-AutoUpgrade.log" 
} else { 
    "C:\ProgramData\chocolatey\logs\Chocolatey-AutoUpgrade.log" 
}

if (Test-Path $logPath) {
    Write-Host "   ✅ Log file found at: $logPath" -ForegroundColor Green
    $logInfo = Get-Item $logPath
    Write-Host "   📏 Size: $([Math]::Round($logInfo.Length / 1KB, 2)) KB" -ForegroundColor Cyan
    Write-Host "   📅 Modified: $($logInfo.LastWriteTime)" -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host "   📜 Last 10 lines of log:" -ForegroundColor Yellow
    Get-Content $logPath -Tail 10 | ForEach-Object { Write-Host "      $_" -ForegroundColor Gray }
} else {
    Write-Host "   ⚠️  Log file not found (task may not have run yet)" -ForegroundColor Yellow
}

# 6. Test chocolatey directly
Write-Host ""
Write-Host "6️⃣  Testing Chocolatey directly..." -ForegroundColor Yellow
Write-Host "   Would you like to test 'choco upgrade all --dry-run'? (y/n): " -ForegroundColor Magenta -NoNewline
$response = Read-Host

if ($response -eq 'y') {
    try {
        $chocoPath = if ($env:ChocolateyInstall) { "$env:ChocolateyInstall\bin\choco.exe" } else { "C:\ProgramData\chocolatey\bin\choco.exe" }
        Write-Host "   🍫 Running Chocolatey upgrade in dry-run mode..." -ForegroundColor Yellow
        & $chocoPath upgrade all --dry-run --limit-output
        Write-Host "   ✅ Chocolatey test completed successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "   ❌ Chocolatey test failed: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "══════════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host "🏁 Validation complete!" -ForegroundColor Cyan