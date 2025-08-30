' OpenDailyPage.vbs
Set sh = CreateObject("WScript.Shell")
sh.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File ""C:\Scripts\open_daily_page.ps1""", 0, False
