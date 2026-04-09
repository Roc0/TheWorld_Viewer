@echo off

set curpath=%~dp0
cd /D %curpath%

set project=--path %curpath%TheWorld

copy /Y ..\TheWorld_GDN_Viewer\x64\*.dll %curpath%TheWorld\addons\twviewer\native\
copy /Y ..\shapelib\shapelib.dll %curpath%TheWorld\addons\twviewer\native\

rem CUSTOM BUILD RELEASE single	precision	==> scons platform=windows bits=64 -j11 vsproj=yes target=editor
set executable=..\..\Client\godot\bin\godot.windows.template_release.x86_64.exe

rem CUSTOM BUILD DEBUG single precision		==> scons platform=windows bits=64 -j11 vsproj=yes target=editor dev_build=yes
rem set executable=..\..\Client\godot\bin\godot.windows.editor.dev.x86_64.exe

				rem rem rem rem rem rem rem CUSTOM BUILD RELEASE double	precision	==> scons platform=windows bits=64 -j10 vsproj=yes target=editor precision=double
				rem rem rem rem rem rem rem set executable=..\..\Client\godot\bin\godot.windows.editor.double.x86_64.exe

				rem rem rem rem rem rem rem CUSTOM BUILD DEBUG double precision		==> scons platform=windows bits=64 -j10 vsproj=yes target=editor dev_build=yes precision=double
				rem rem rem rem rem rem rem set executable=..\..\Client\godot\bin\godot.windows.editor.dev.double.x86_64.exe

rem RELEASE single OFFICIAL
rem set executable=..\..\Client\godot\Bin\Godot_v4.6.2-stable_win64.exe

dir %executable%
set command=%executable% -v %project%
echo %command%
call %command% 2>&1 1>log.txt
rem call %executable% -v %project% %edit% 2>&1 1>log.txt
rem pause

