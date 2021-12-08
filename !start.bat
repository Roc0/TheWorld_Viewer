@echo off
set curpath=%~dp0

rem copy /Y ..\<GDNative Project>\x64\*.dll %curpath%godot_proj\GDN\

cd /D %curpath%
call Godot_v3.4-stable_win64.exe -v --path %curpath%godot_proj -e
