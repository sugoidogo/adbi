# ADB-Installer
Download from [Releases](https://github.com/josephsmendoza/ADB-Installer/releases)

This is a re-implementation of the [15 seconds ADB Installer](https://forum.xda-developers.com/showthread.php?t=2588979)

This installer requires an internet connection.

The main component is [the PowerShell script](https://github.com/josephsmendoza/ADB-Installer/blob/master/install.ps1) which downloads [the latest android platform tools for windows](https://dl.google.com/android/repository/platform-tools-latest-windows.zip) and installs them to either `C:\adb`, an auto-detected previous install location, or a path you can specify via `-installPath`.

For conveinence, this is wrapped in an `.exe` file which runs the script with `ExecutionPolicy` set to `Bypass`. This file is fully automated.

Icon is from [Google via icon-icons.com](https://icon-icons.com/icon/adb/90476)

Built with [7z SFX Builder](https://sourceforge.net/projects/s-zipsfxbuilder)
