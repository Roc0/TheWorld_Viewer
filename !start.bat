@echo off
set curpath=%~dp0
cd /D %curpath%

copy /Y ..\TheWorld_GDN_Viewer\x64\*.dll %curpath%godot_proj\addons\twviewer\native\
copy /Y ..\shapelib\shapelib.dll %curpath%godot_proj\addons\twviewer\native\


call Godot_v3.5.2-stable_win64.exe -v --path %curpath%godot_proj -e>log.txt
