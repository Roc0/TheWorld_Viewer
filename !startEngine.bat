@echo off
set curpath=%~dp0
cd /D %curpath%

copy /Y ..\TheWorld_GDN_Viewer\x64\*.dll %curpath%TheWorld\addons\twviewer\native\
copy /Y ..\shapelib\shapelib.dll %curpath%TheWorld\addons\twviewer\native\

rem RELEASE single OFFICIAL
rem set executable=Godot_v4.2.1-stable_win64.exe

rem CUSTOM BUILD RELEASE single		==> scons platform=windows bits=64 -j10 vsproj=yes target=editor
set executable=..\..\Prove\godot\bin\godot.windows.editor.x86_64.exe

rem CUSTOM BUILD DEBUG single		==> scons platform=windows bits=64 -j10 vsproj=yes target=editor dev_build=yes
rem set executable=..\..\Prove\godot\bin\godot.windows.editor.dev.x86_64.exe

				rem rem rem rem rem rem rem CUSTOM BUILD RELEASE double		==> scons platform=windows bits=64 -j10 vsproj=yes target=editor precision=double
				rem rem rem rem rem rem rem set executable=..\..\Prove\godot\bin\godot.windows.editor.double.x86_64.exe

				rem rem rem rem rem rem rem CUSTOM BUILD DEBUG double 		==> scons platform=windows bits=64 -j10 vsproj=yes target=editor dev_build=yes precision=double
				rem rem rem rem rem rem rem set executable=..\..\Prove\godot\bin\godot.windows.editor.dev.double.x86_64.exe

dir %executable%
call %executable% 2>&1 1>log.txt
rem pause

