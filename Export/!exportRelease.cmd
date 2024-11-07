@echo off

echo Verificare che TheWorld sia stato compilato in Release ...
echo ... dopo l'esecuzione del comando di export attivare TheWorld.exe o TheWorld.console.exe da D:\TheWorld\Client\TheWorld

pause

set curpath=%~dp0
cd /D %curpath%

set export_dir=..\..\TheWorld
set export_executable=TheWorld.exe

if not exist %export_dir% mkdir %export_dir%

set project=--path %curpath%..\TheWorld
set export=--export-release "Windows Desktop" ..\Export\%export_dir%\%export_executable%

set executable=..\..\..\Client\godot\bin\godot.windows.editor.x86_64.exe

dir %executable%
set command=%executable% -v --headless %project% %export%
echo %command%
call %command% 2>&1 1>log.txt

set ground_textures_path=Client\assets\textures\ground
if not exist %curpath%%export_dir%\%ground_textures_path% mkdir %curpath%%export_dir%\%ground_textures_path%
copy /Y ..\TheWorld\assets\textures\ground\*.ground* %curpath%%export_dir%\%ground_textures_path%

pause

