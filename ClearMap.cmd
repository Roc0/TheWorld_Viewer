@echo off
set MAPNAME=%1
if a%MAPNAME% == a goto Fine

	del /Q /S %appdata%\Godot\app_userdata\TheWorld\Cache\maps\%MAPNAME%\*.mesh
	del /Q /S %appdata%\Godot\app_userdata\TheWorld\Cache\maps\%MAPNAME%\*.png
	
	del /Q /S D:\TheWorld\Client\TheWorld_MapManager\Data\Cache\maps\%MAPNAME%\*.mesh
	del /Q /S D:\TheWorld\Client\TheWorld_MapManager\Data\Cache\maps\%MAPNAME%\MapRect_*
	
	del /Q /S D:\TheWorld\Client\TheWorld_MapManager\Data\DBJson\maps\%MAPNAME%\X-*
	del /Q /S D:\TheWorld\Client\TheWorld_MapManager\Data\DBJson\maps\%MAPNAME%\MapRect_*
	
	rem del /Q C:\Users\Riccardo\AppData\Roaming\Godot\app_userdata\TheWorld\Cache\maps\%MAPNAME%\ST-4.000000_SZ-2049\L-0\MapRects\*.*
	rem del /Q C:\Users\Riccardo\AppData\Roaming\Godot\app_userdata\TheWorld\Cache\maps\%MAPNAME%\ST-4.000000_SZ-2049\L-0\Work\*.*
	rem del /Q C:\Users\Riccardo\AppData\Roaming\Godot\app_userdata\TheWorld\Cache\maps\%MAPNAME%\ST-4.000000_SZ-2049\L-0\*.mesh
	rem del /Q D:\TheWorld\Client\TheWorld_MapManager\Data\Cache\maps\%MAPNAME%\ST-4.000000_SZ-2049\L-0\*.mesh
	rem del /Q D:\TheWorld\Client\TheWorld_MapManager\Data\Cache\maps\%MAPNAME%\ST-4.000000_SZ-2049\L-0\Work\*.mesh
	rem del /Q D:\TheWorld\Client\TheWorld_MapManager\Data\DBJson\maps\%MAPNAME%\ST-4.000000_SZ-2049\L-0\MapRects\*.*
	rem del /Q D:\TheWorld\Client\TheWorld_MapManager\Data\DBJson\maps\%MAPNAME%\ST-4.000000_SZ-2049\L-0\*.json

:Fine
