@echo off
setlocal EnableExtensions
title Gamey

fltmc >nul 2>&1 && goto :Elevated
powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs -WindowStyle Minimized"
exit /b
:Elevated
cd /d "%~dp0"
timeout /t 2 /nobreak >nul
for /f %%C in ('powershell -NoProfile -Command "@(Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'cmd.exe' -and $_.CommandLine -like '*gamey.ba[t]*' }).Count"') do if %%C gtr 1 exit /b
goto :Config

:: ---- CALLS (:: in front = off, each one reverts itself) ----
:Boost
call :PowerPlan
call :Processes
:: call :Services
:: call :Explorer
call :GamePriority
goto :eof

:Config
:: ---- LISTS ----
set "GAMELIST=eldenring.exe cs2.exe RDR2.exe Discovery-d.exe VALORANT-Win64-Shipping.exe PioneerGame.exe deadlock.exe"
set "PROCESSLIST=CrossDeviceResume.exe MicrosoftEdgeUpdate.exe Spotify.exe CrossDeviceService.exe"
set "SERVICELIST="
set "RAMFLAGS=-Ew -Es -Em -Et -E0"

:: ---- SETTINGS ----
set "RAMMAP=C:\Tools\Sysinternals\RAMMap64.exe"
set "PLAN_BALANCED=381b4222-f694-41f0-9685-ff5bb260df2e"
set "PLAN_HIGH=8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
set "POLL_SECONDS=5"
set "STATE=%~dp0gamey.state"

if exist "%STATE%" call :Recover

:: ---- WATCH ----
echo gamey is watching for a game ...
:Watch
set "ACTIVE_GAME="
if defined IGNORE_GAME tasklist /fi "imagename eq %IGNORE_GAME%" /fo csv /nh 2>nul | find /i "%IGNORE_GAME%" >nul || set "IGNORE_GAME="
for %%G in (%GAMELIST%) do (
    if /i not "%%~G"=="%IGNORE_GAME%" if not defined ACTIVE_GAME tasklist /fi "imagename eq %%~G" /fo csv /nh 2>nul | find /i "%%~G" >nul && set "ACTIVE_GAME=%%~G"
)
if defined ACTIVE_GAME goto :Found
timeout /t %POLL_SECONDS% /nobreak >nul
goto :Watch

:Found
echo Game detected: %ACTIVE_GAME%
for %%A in ("%ACTIVE_GAME%") do set "ACTIVE_GAME_NAME=%%~nA"
set "UNDO="

:: ---- BOOST ----
call :Boost
call :ClearRam

:: ---- WAIT, THEN UNDO WHAT RAN ----
call :WaitForExit
for %%U in (%UNDO%) do call :Undo_%%U
del "%STATE%" >nul 2>&1

echo Back to normal.
set "IGNORE_GAME=%ACTIVE_GAME%"
echo Watching again ...
goto :Watch

:: ---- BOOST FUNCTIONS ----
:PowerPlan
echo High performance ...
powercfg /setactive %PLAN_HIGH% >nul 2>&1 || (
    powercfg /duplicatescheme %PLAN_HIGH% %PLAN_HIGH% >nul 2>&1
    powercfg /setactive %PLAN_HIGH% >nul 2>&1
)
call :AddUndo PowerPlan
goto :eof

:Processes
echo Closing processes ...
for %%P in (%PROCESSLIST%) do if /i not "%%~P"=="%ACTIVE_GAME%" taskkill /f /im "%%~P" >nul 2>&1
goto :eof

:Services
echo Stopping services ...
for %%S in (%SERVICELIST%) do (
    sc query "%%~S" 2>nul | find "RUNNING" >nul && (
        set "WAS_RUNNING_%%~S=1"
        net stop "%%~S" /y >nul 2>&1
    )
)
call :AddUndo Services
goto :eof

:Explorer
echo Stopping explorer ...
taskkill /f /im explorer.exe >nul 2>&1
call :AddUndo Explorer
goto :eof

:GamePriority
echo Game priority: Above Normal ...
set "PRIO=AboveNormal"
call :SetPriority
call :AddUndo GamePriority
goto :eof

:ClearRam
echo Clearing RAM ...
if not exist "%RAMMAP%" (echo RAMMap not found - skipping & goto :eof)
for %%F in (%RAMFLAGS%) do start "" /wait "%RAMMAP%" -accepteula %%F
goto :eof

:: ---- UNDO FUNCTIONS (called automatically, name = Undo_ + boost name) ----
:Undo_PowerPlan
powercfg /setactive %PLAN_BALANCED% >nul 2>&1
goto :eof

:Undo_Services
for %%S in (%SERVICELIST%) do if defined WAS_RUNNING_%%~S net start "%%~S" >nul 2>&1
goto :eof

:Undo_Explorer
tasklist /fi "imagename eq explorer.exe" /nh 2>nul | find /i "explorer.exe" >nul || runas /trustlevel:0x20000 "%SystemRoot%\explorer.exe"
:: elevated fallback: start "" "%SystemRoot%\explorer.exe"
goto :eof

:Undo_GamePriority
if not defined ACTIVE_GAME_NAME goto :eof
set "PRIO=Normal"
call :SetPriority
goto :eof

:: ---- HELPERS ----
:AddUndo
set "UNDO=%~1 %UNDO%"
>"%STATE%" echo %UNDO%
goto :eof

:Recover
echo Previous session did not revert - recovering ...
set /p UNDO=<"%STATE%"
for %%S in (%SERVICELIST%) do set "WAS_RUNNING_%%~S=1"
for %%U in (%UNDO%) do call :Undo_%%U
del "%STATE%" >nul 2>&1
goto :eof

:SetPriority
powershell -NoProfile -Command "Get-Process -Name $env:ACTIVE_GAME_NAME -ErrorAction SilentlyContinue | ForEach-Object { try { $_.PriorityClass = $env:PRIO } catch {} }"
goto :eof

:WaitForExit
echo.
echo gamey ON. Reverts when %ACTIVE_GAME% closes, or press ENTER here.
powershell -NoProfile -Command ^
    "$name = $env:ACTIVE_GAME_NAME;" ^
    "while ($true) {" ^
    "    if (-not (Get-Process -Name $name -ErrorAction SilentlyContinue)) { exit 0 }" ^
    "    if ([Console]::KeyAvailable -and [Console]::ReadKey($true).Key -eq 'Enter') { exit 1 }" ^
    "    Start-Sleep -Milliseconds 500" ^
    "}"
if "%errorlevel%"=="1" (echo ENTER pressed - reverting ...) else (echo Game closed - reverting ...)
goto :eof
