Param( [Parameter(Position=0)] [String[]] $installPath )
Set-PSDebug -Trace 2
$ErrorActionPreference = 'Inquire'
$adbUrl = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
$adbZip = "$env:temp\platform-tools-latest-windows.zip"
$adbProcess = Get-Process -Name adb -ErrorAction SilentlyContinue
$shell = New-Object -ComObject Wscript.Shell
$fastboot = Get-Command "fastboot" -ErrorAction SilentlyContinue 

$adbDownloadJob = Start-Job -ScriptBlock {
    $ErrorActionPreference = 'Inquire'
    Write-Verbose "Start-BitsTransfer -Source $using:adbURL -Destination $using:adbZip" -Verbose
    Start-BitsTransfer -Source $using:adbURL -Destination $using:adbZip
}

$adbSearchJob = Start-Job -ScriptBlock {
    $ErrorActionPreference = 'Inquire'
    Get-ChildItem -Path $env:SystemDrive\ -Include "adb.exe","fastboot.exe" -Exclude $env:SystemRoot\*,(Split-Path -Path $HOME)\* -ErrorAction SilentlyContinue -Recurse | ForEach-Object {Split-Path -Path $_.FullName} | Select-Object -Unique
}

$adbUserSearchJob = Start-Job -ScriptBlock {
    $ErrorActionPreference = 'Inquire'
    Get-ChildItem -Path $HOME\ -Include "adb.exe","fastboot.exe" -Exclude $env:temp\* -ErrorAction SilentlyContinue -Recurse -Force | ForEach-Object {Split-Path -Path $_.FullName} | Select-Object -Unique
}

if($adbProcess){
    $adb=$adbProcess.Path
    $adbProcess.Kill()
} else {
    $adb=Get-Command "adb" -ErrorAction SilentlyContinue
}

if(!$installPath){
    if(!$adb -and $fastboot){
        $installPath=&$fastboot --version | Select-String -Pattern "(?<=installed as )(.+)(?=\\.*\.exe)" | % { $_.Matches } | % { $_.Value }
    }
    if($adb){
        $installPath=&$adb --version | Select-String -Pattern "(?<=installed as )(.+)(?=\\.*\.exe)" | % { $_.Matches } | % { $_.Value }
    }
    if(!$installPath){
        $installPath="C:\android-platform-tools"
        if($shell.Popup("automatic adb locating failed, Would you like to search for a previously downloaded adb? This process can take a long time, depending on how fast your storage device is",
        0,'ADB Installer',36) -eq 6){
            $result=@($installPath)
            $result+=Receive-Job -Job $adbUserSearchJob -Wait -AutoRemoveJob
            $result+=Receive-Job -Job $adbSearchJob -Wait -AutoRemoveJob
            $installPath=($result | Out-GridView -OutputMode Single)
        } else {
            Remove-Job $adbSearchJob -Force
            Remove-Job $adbUserSearchJob -Force
        }
    }
}

$oldpath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).path
if( !$oldpath.Contains($installPath) ){
$newpath = "$oldpath;$installPath"
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath
}

if ( (cmd /c sc query Windefend) -like "*RUNNING*" ){
    Add-MpPreference -ExclusionPath $installPath
    Add-MpPreference -ExclusionProcess "adb.exe"
} else {
    $shell.Popup("Windows Defender is not running! If you have antivirus, exclude $installPath")
}

Receive-Job -Job $adbDownloadJob -Wait -AutoRemoveJob
Start-Job -ScriptBlock {
    $ErrorActionPreference = 'Inquire'
    Write-Verbose "Expand-Archive -Path $using:adbZip -DestinationPath $env:temp -Force" -Verbose
    Expand-Archive -Path $using:adbZip -DestinationPath $env:temp -Force
    Remove-Item $using:adbZip -Verbose
} | Receive-Job -Wait -AutoRemoveJob
if(!(Test-Path $installPath)){mkdir $installPath}
Copy-Item -Path "$env:temp\platform-tools\*" -Destination "$installPath\" -Force
Remove-Item -Path "$env:temp\platform-tools" -Recurse -Force

$shell.Popup("Done!")