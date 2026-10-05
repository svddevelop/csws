set "pp=Z:\WI\pcb\AutoControlTool\techtool\scws"

mkdir "%pp%\aarch64-linux"
mkdir "%pp%\x86_64-linux"
mkdir "%pp%\x86_64-win64"

copy /Y aarch64-linux\csws  "%pp%\aarch64-linux\"
copy /Y x86_64-linux\csws   "%pp%\x86_64-linux\"
copy /Y x86_64-win64\csws.exe "%pp%\x86_64-win64\"

