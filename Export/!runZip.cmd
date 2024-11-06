@echo off

set curpath=%~dp0
cd /D %curpath%

set export_dir=TheWorld
set export_executable=TheWorld.exe
set export_zip=TheWorld.zip

if not exist %export_dir% mkdir %export_dir%

set executable=%curpath%%export_dir%\%export_executable%
dir %executable%

set command=%executable% --main-pack %curpath%%export_dir%\%export_zip%
echo %command%
call %command% 2>&1 1>log.txt

pause

