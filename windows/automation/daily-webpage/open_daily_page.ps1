# open_daily_page.ps1
$Url     = "https://www.dppl.org/resources/subjects/paywall-free-newspapers"
$Browser = "C:\Program Files\Mozilla Firefox\firefox.exe"

$FlagDir   = Join-Path $env:LOCALAPPDATA "DailyWebpage"
$TodayFlag = Join-Path $FlagDir ("{0}.flag" -f (Get-Date -Format 'yyyy-MM-dd'))
$LogFile   = Join-Path $FlagDir "run.log"

New-Item -ItemType Directory -Path $FlagDir -Force | Out-Null

Add-Content -Path $LogFile -Value ("{0} Triggered" -f (Get-Date -Format o))

if (Test-Path $TodayFlag) {
  Add-Content -Path $LogFile -Value "…Skipped (already ran today)."
  exit 0
}

New-Item -ItemType File -Path $TodayFlag -Force | Out-Null
Add-Content -Path $LogFile -Value "…Launching browser."
Start-Process $Browser $Url
