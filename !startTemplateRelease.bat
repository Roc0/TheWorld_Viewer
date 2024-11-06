@echo off

set curpath=%~dp0
cd /D %curpath%

set project=--path %curpath%TheWorld

copy /Y ..\TheWorld_GDN_Viewer\x64\*.dll %curpath%TheWorld\addons\twviewer\native\
copy /Y ..\shapelib\shapelib.dll %curpath%TheWorld\addons\twviewer\native\

rem RELEASE single OFFICIAL
rem set executable=Godot_v4.2.1-stable_win64.exe

rem CUSTOM BUILD RELEASE single	precision	==> scons platform=windows bits=64 -j11 vsproj=yes target=editor
rem godot		commit 77dcf97d82cbfe4e4615475fa52ca03da645dbd8 (HEAD, tag: 4.3-stable)				Hash 77dcf97d82 (git rev-parse --short HEAD)	HEAD detached at 4.3-stable (git status)
set executable=..\..\Client\godot\bin\godot.windows.template_release.x86_64.exe

rem CUSTOM BUILD DEBUG single precision		==> scons platform=windows bits=64 -j11 vsproj=yes target=editor dev_build=yes
rem godot		commit 77dcf97d82cbfe4e4615475fa52ca03da645dbd8 (HEAD, tag: 4.3-stable)				Hash 77dcf97d82 (git rev-parse --short HEAD)	HEAD detached at 4.3-stable (git status)
rem set executable=..\..\Client\godot\bin\godot.windows.editor.dev.x86_64.exe

				rem rem rem rem rem rem rem CUSTOM BUILD RELEASE double	precision	==> scons platform=windows bits=64 -j10 vsproj=yes target=editor precision=double
				rem rem rem rem rem rem rem set executable=..\..\Client\godot\bin\godot.windows.editor.double.x86_64.exe

				rem rem rem rem rem rem rem CUSTOM BUILD DEBUG double precision		==> scons platform=windows bits=64 -j10 vsproj=yes target=editor dev_build=yes precision=double
				rem rem rem rem rem rem rem set executable=..\..\Client\godot\bin\godot.windows.editor.dev.double.x86_64.exe

dir %executable%
set command=%executable% -v %project%
echo %command%
call %command% 2>&1 1>log.txt
rem call %executable% -v %project% %edit% 2>&1 1>log.txt
rem pause

