Param( [Parameter(Position=0)] [String[]] $installPath )
Set-PSDebug -Trace 2
$ErrorActionPreference = 'Inquire'
$shell = New-Object -ComObject Wscript.Shell
$adb=Get-Command "adb" -ErrorAction SilentlyContinue
$fastboot=Get-Command "fastboot" -ErrorAction SilentlyContinue

if($installPath.Length.Equals(0)){
if(!$adb -and $fastboot){
$installPath=fastboot --version | Select-String -Pattern "(?<=installed as )(.+)(?=\\.*\.exe)" | % { $_.Matches } | % { $_.Value }
}
if($adb){
$installPath=adb --version | Select-String -Pattern "(?<=installed as )(.+)(?=\\.*\.exe)" | % { $_.Matches } | % { $_.Value }
Invoke-Command -ScriptBlock {
$ErrorActionPreference = 'Ignore'
adb kill-server
}
}
if($installPath.Length.Equals(0)){
$installPath="$env:APPDATA\SideQuest\platform-tools"
}
}

if ( (cmd /c sc query Windefend) -like "*RUNNING*" ){
Add-MpPreference -ExclusionPath $installPath
Add-MpPreference -ExclusionProcess "adb.exe"
} else {
$shell.Popup("Windows Defender is not running!
If you have antivirus, exclude $installPath")
}

if(!$adb -and !$fastboot){
$oldpath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).path
$newpath = "$oldpath;$installPath"
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath
}

Import-Module BitsTransfer
Start-BitsTransfer -Source "https://dl.google.com/android/repository/platform-tools-latest-windows.zip" -Destination "$env:temp\platform-tools-latest-windows.zip"
Set-PSDebug -Off
Expand-Archive -Path "$env:temp\platform-tools-latest-windows.zip" -DestinationPath "$env:temp" -Force
Set-PSDebug -Trace 2
Copy-Item -Path "$env:temp\platform-tools\*" -Destination "$installPath\" -Force

$PSScriptRootLegacy=split-path -parent $MyInvocation.MyCommand.Definition
Start-Process $PSScriptRootLegacy/android_winusb.inf -Verb Install

$shell.Popup("Done!")