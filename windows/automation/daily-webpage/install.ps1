# 1) Copy scripts into place
param(
  [string]$TaskName   = "OpenDailyPageOnUnlock",
  [string]$TargetDir  = "C:\Scripts",
  [string]$RepoDir    = (Split-Path -Parent $MyInvocation.MyCommand.Path),
  [string]$TaskXml    = (Join-Path $RepoDir "task.xml")
)

$ErrorActionPreference = "Stop"

New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
$files = @("open_daily_page.ps1","open_daily_page.vbs")
foreach($f in $files){
  $src = Join-Path $RepoDir $f
  $dst = Join-Path $TargetDir $f
  if(!(Test-Path $src)){ Write-Error "Missing $src"; exit 1 }
  $srcHash = (Get-FileHash $src).Hash
  $dstHash = (Get-FileHash $dst -ErrorAction SilentlyContinue).Hash
  if($srcHash -ne $dstHash){ Copy-Item $src $dst -Force }
}

# 2) Load & normalize task XML for this machine
[xml]$xml = Get-Content -LiteralPath $TaskXml

# 3) 
# --- Namespace manager (required because task.xml has a default namespace) ---
$ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
$ns.AddNamespace('t','http://schemas.microsoft.com/windows/2004/02/mit/task')

# --- Resolve current user's SID robustly ---
try {
  $acct = New-Object System.Security.Principal.NTAccount("$env:UserDomain",$env:UserName)
  $sid  = $acct.Translate([System.Security.Principal.SecurityIdentifier]).Value
} catch {
  $sid = (whoami /user /FO CSV | ConvertFrom-Csv).SID
}

# -------- Principals: run as current user, interactive, least privilege --------
$principal = $xml.SelectSingleNode('//t:Task/t:Principals/t:Principal', $ns)
if (-not $principal) {
  $principals = $xml.SelectSingleNode('//t:Task/t:Principals', $ns)
  if (-not $principals) {
    $principals = $xml.CreateElement('Principals',$ns.LookupNamespace('t'))
    $xml.Task.AppendChild($principals) | Out-Null
  }
  $principal = $xml.CreateElement('Principal',$ns.LookupNamespace('t'))
  $principals.AppendChild($principal) | Out-Null
}

# ensure required child nodes exist
function Ensure-Child($parent,$name){
  $node = $parent.SelectSingleNode("t:$name",$ns)
  if (-not $node) {
    $node = $xml.CreateElement($name,$ns.LookupNamespace('t'))
    $parent.AppendChild($node) | Out-Null
  }
  $node
}

(Ensure-Child $principal 'UserId').InnerText    = $sid
(Ensure-Child $principal 'LogonType').InnerText = 'InteractiveToken'
(Ensure-Child $principal 'RunLevel').InnerText  = 'LeastPrivilege'
# keep id stable for Actions Context attribute
if (-not $principal.HasAttribute('id')) { $principal.SetAttribute('id','Author') }

# -------- Trigger: scope unlock to this user --------
$unlock = $xml.SelectSingleNode('//t:Task/t:Triggers/t:SessionStateChangeTrigger', $ns)
if ($unlock) {
  # some exports use <StateChange>SessionUnlock</StateChange> (valid); keep as-is
  (Ensure-Child $unlock 'UserId').InnerText = $sid
}

# -------- Settings: reliability/limits --------
$settings = $xml.SelectSingleNode('//t:Task/t:Settings', $ns)
if (-not $settings) {
  $settings = $xml.CreateElement('Settings',$ns.LookupNamespace('t'))
  $xml.Task.AppendChild($settings) | Out-Null
}
(Ensure-Child $settings 'MultipleInstancesPolicy').InnerText    = 'IgnoreNew'
(Ensure-Child $settings 'DisallowStartIfOnBatteries').InnerText = 'false'
(Ensure-Child $settings 'StopIfGoingOnBatteries').InnerText     = 'false'
(Ensure-Child $settings 'ExecutionTimeLimit').InnerText         = 'PT5M'

# -------- Action: wscript + quoted VBS path + working dir --------
$exec = $xml.SelectSingleNode('//t:Task/t:Actions/t:Exec', $ns)
if (-not $exec) {
  $actions = $xml.SelectSingleNode('//t:Task/t:Actions', $ns)
  if (-not $actions) {
    $actions = $xml.CreateElement('Actions',$ns.LookupNamespace('t'))
    $xml.Task.AppendChild($actions) | Out-Null
  }
  $exec = $xml.CreateElement('Exec',$ns.LookupNamespace('t'))
  $actions.AppendChild($exec) | Out-Null
}

(Ensure-Child $exec 'Command').InnerText          = 'wscript.exe'
(Ensure-Child $exec 'Arguments').InnerText        = '"' + (Join-Path $TargetDir 'open_daily_page.vbs') + '"'
(Ensure-Child $exec 'WorkingDirectory').InnerText = $TargetDir

# Keep Actions Context pointing at 'Author' principal
$actionsNode = $xml.SelectSingleNode('//t:Task/t:Actions', $ns)
if ($actionsNode -and -not $actionsNode.GetAttribute('Context')) {
  $actionsNode.SetAttribute('Context','Author')
}

# -------- Optional: set a generic Author (metadata only) --------
$authorNode = $xml.SelectSingleNode('//t:Task/t:RegistrationInfo/t:Author', $ns)
if ($authorNode) { $authorNode.InnerText = "$env:UserDomain\$env:UserName" }

# Done: $xml.OuterXml now has all machine/user-specific updates

# 4) Register (idempotent)
Register-ScheduledTask -TaskName $TaskName -Xml $xml.OuterXml -Force | Out-Null

# Law 3: minimal, useful output
Write-Host "Installed task: $TaskName"
Write-Host "Scripts dir   : $TargetDir"
Write-Host "Logs          : $env:LOCALAPPDATA\DailyWebpage\run.log"
