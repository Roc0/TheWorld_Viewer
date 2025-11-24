@echo off
set MAPNAME=%1
if a%MAPNAME% == a goto Fine

	del /Q C:\Users\Riccardo\AppData\Roaming\Godot\app_userdata\TheWorld\Cache\maps\%MAPNAME%\ST-4.000000_SZ-2049\L-0\MapRects\*.*
	del /Q C:\Users\Riccardo\AppData\Roaming\Godot\app_userdata\TheWorld\Cache\maps\%MAPNAME%\ST-4.000000_SZ-2049\L-0\Work\*.*
	del /Q C:\Users\Riccardo\AppData\Roaming\Godot\app_userdata\TheWorld\Cache\maps\%MAPNAME%\ST-4.000000_SZ-2049\L-0\*.mesh
	del /Q D:\TheWorld\Client\TheWorld_MapManager\Data\Cache\maps\%MAPNAME%\ST-4.000000_SZ-2049\L-0\*.mesh
	del /Q D:\TheWorld\Client\TheWorld_MapManager\Data\Cache\maps\%MAPNAME%\ST-4.000000_SZ-2049\L-0\Work\*.mesh
	del /Q D:\TheWorld\Client\TheWorld_MapManager\Data\DBJson\maps\%MAPNAME%\ST-4.000000_SZ-2049\L-0\MapRects\*.*
	del /Q D:\TheWorld\Client\TheWorld_MapManager\Data\DBJson\maps\%MAPNAME%\ST-4.000000_SZ-2049\L-0\*.json

:Fine
