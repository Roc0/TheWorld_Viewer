@echo off

echo Verificare che TheWorld sia stato compilato in Debug... e che i template relativi alla versione corrente di godot siano stati scaricati usando l'editor "Editor\Manage Export Templates..."
echo ... dopo l'esecuzione del comando di export attivare TheWorld.exe o TheWorld.console.exe da D:\TheWorld\Client\TheWorld

pause

set curpath=%~dp0
cd /D %curpath%

set export_dir=..\..\TheWorld
set export_executable=TheWorld.exe

if not exist %export_dir% mkdir %export_dir%

set project=--path %curpath%..\TheWorld
set export=--export-debug "Windows Desktop" ..\Export\%export_dir%\%export_executable%

set executable=..\..\..\Client\godot\bin\godot.windows.editor.x86_64.exe

dir %executable%
set command=%executable% -v --headless %project% %export%
echo %command%
call %command% 2>&1 1>log.txt

set ground_textures_path=Client\assets\textures\ground
if not exist %curpath%%export_dir%\%ground_textures_path% mkdir %curpath%%export_dir%\%ground_textures_path%
robocopy ..\TheWorld\assets\textures\ground\ %curpath%%export_dir%\%ground_textures_path% /E /R:10 /V /MIR /XD "_src"

pause

