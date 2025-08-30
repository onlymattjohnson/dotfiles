param(
  [string]$TaskName = "OpenDailyPageOnUnlock",
  [switch]$Purge
)

$ErrorActionPreference = "Stop"

if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
  Write-Host "Removed task: $TaskName"
}

if ($Purge) {
  Remove-Item "C:\Scripts\open_daily_page.ps1","C:\Scripts\open_daily_page.vbs" -ErrorAction SilentlyContinue
  Remove-Item "$env:LOCALAPPDATA\DailyWebpage" -Recurse -Force -ErrorAction SilentlyContinue
  Write-Host "Purged scripts and logs."
}
