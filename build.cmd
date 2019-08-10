gradle runtime
ptiso create -z lzma -c crc32 -x stub ptse_cmd.stub -x runas admin -x mount_system_visible 0 -x process_visible 1 -x run_relative 1 -x use_stderr 1 -x run_exe bin/ADB-Installer.bat -x icon adb.ico ADB-Installer.exe build\image
