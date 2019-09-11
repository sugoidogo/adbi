cd ..
dub build --single src/adbi.d
dub build --single src/common.d
ptiso create -z lzma -c crc32 -x stub res/ptse_cmd.stub -x runas admin -x mount_system_visible 0 -x process_visible 1 -x run_relative 1 -x run_exe adbi.cmd -x icon res/adb.ico adbi.exe bin/windows/x86_64