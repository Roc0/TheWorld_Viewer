@echo off

set curpath=%~dp0
cd /D %curpath%

..\Bin\Listdlls64.exe -u godot | grep -i theworld

pause