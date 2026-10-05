set "ret=%CD%"
cd "Z:\fpcupdeluxe\fpc\bin\x86_64-win64"
windres.exe -i "%ret%\favicon.rc" -o "%ret%\favicon.res"
cd "%ret%"
copy favicon.res src\https\srv\ 