@echo off

set curpath=%~dp0
cd /D %curpath%

set edit=-e
if b%1 == bnoedit set edit=

set project=--path %curpath%TheWorld
if b%2 == bnoproject set project=

copy /Y ..\TheWorld_GDN_Viewer\x64\*.dll %curpath%TheWorld\addons\twviewer\native\
copy /Y ..\shapelib\shapelib.dll %curpath%TheWorld\addons\twviewer\native\

rem RELEASE single OFFICIAL
rem set executable=Godot_v4.2.1-stable_win64.exe

rem CUSTOM BUILD RELEASE single	precision	==> scons platform=windows bits=64 -j11 vsproj=yes target=editor
rem godot 4.3 beta 3 HEAD detached at 82cedc83c9 - godot.cpp 4.3 HEAD detached at a62f633
set executable=..\..\Prove\godot\bin\godot.windows.editor.x86_64.exe

rem CUSTOM BUILD DEBUG single precision		==> scons platform=windows bits=64 -j11 vsproj=yes target=editor dev_build=yes
rem godot 4.3 beta 3 HEAD detached at 82cedc83c9 - godot.cpp 4.3 HEAD detached at a62f633
rem set executable=..\..\Prove\godot\bin\godot.windows.editor.dev.x86_64.exe

				rem rem rem rem rem rem rem CUSTOM BUILD RELEASE double	precision	==> scons platform=windows bits=64 -j10 vsproj=yes target=editor precision=double
				rem rem rem rem rem rem rem set executable=..\..\Prove\godot\bin\godot.windows.editor.double.x86_64.exe

				rem rem rem rem rem rem rem CUSTOM BUILD DEBUG double precision		==> scons platform=windows bits=64 -j10 vsproj=yes target=editor dev_build=yes precision=double
				rem rem rem rem rem rem rem set executable=..\..\Prove\godot\bin\godot.windows.editor.dev.double.x86_64.exe

dir %executable%
call %executable% -v %project% %edit% 2>&1 1>log.txt
rem pause

