# Open Daily Page on First Unlock (Windows)

## Install
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
cd windows/daily-webpage
.\install.ps1 -TaskName "OpenDailyPageOnUnlock"
```

## Uninstall

```powershell
cd windows/daily-webpage
.\uninstall.ps1 -TaskName "OpenDailyPageOnUnlock" -Purge
```

* Scripts live in `C:\Scripts`
* Logs at `%LOCALAPPDATA%\DailyWebpage\run.log`
* Trigger: **On workstation unlock** (first unlock per day guarded by the PS1)