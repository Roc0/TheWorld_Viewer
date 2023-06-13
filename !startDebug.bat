@echo off
set curpath=%~dp0
cd /D %curpath%

copy /Y ..\TheWorld_GDN_Viewer\x64\*.dll %curpath%TheWorld\addons\twviewer\native\
copy /Y ..\shapelib\shapelib.dll %curpath%TheWorld\addons\twviewer\native\

call ..\..\Prove\godot\bin\godot.windows.editor.dev.x86_64.console.exe -v --path %curpath%TheWorld -e>log.txt

