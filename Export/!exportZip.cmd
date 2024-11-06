@echo off

set curpath=%~dp0
cd /D %curpath%

set export_dir=TheWorld
set export_executable=TheWorld.zip

if not exist %export_dir% mkdir %export_dir%

set project=--path %curpath%..\TheWorld
set export=--export-pack "Windows Desktop" ..\Export\%export_dir%\%export_executable%

set executable=..\..\..\Client\godot\bin\godot.windows.editor.x86_64.exe

dir %executable%
set command=%executable% -v --headless %project% %export%
echo %command%
call %command% 2>&1 1>log.txt

pause

