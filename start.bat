@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title Snapgent Bridge (VS Code & Zed Editor)
cd /d "%~dp0"

if not exist "%~dp0logs" mkdir "%~dp0logs" >nul 2>nul
set "LOGFILE=%~dp0logs\start.log"

REM Check for Python 3
set "PY="
where python >nul 2>nul
if %errorlevel% equ 0 (
    python -c "import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)" >nul 2>nul
    if !errorlevel! equ 0 set "PY=python"
)
if not defined PY (
    where py >nul 2>nul
    if !errorlevel! equ 0 (
        py -3 -c "import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)" >nul 2>nul
        if !errorlevel! equ 0 set "PY=py -3"
    )
)

if defined PY (
    echo.
    echo   Configuring MCP servers (VS Code ^& Zed Editor)...
    %PY% "%~dp0setup-config.py"
    echo.
    %PY% -c "import websockets" >nul 2>nul
    if !errorlevel! neq 0 (
        echo   Installing websockets...
        %PY% -m pip install websockets
    )
) else (
    echo.
    echo   Configuring MCP servers...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-config.ps1"
)

REM Free bridge ports 17613 and 17614
for %%P in (17613 17614) do (
    for /f "tokens=5" %%a in ('netstat -aon ^| findstr :%%P ^| findstr LISTENING 2^>nul') do (
        echo   Replacing previous bridge (PID %%a) on port %%P...
        taskkill /F /T /PID %%a >nul 2>nul
        timeout /t 1 /nobreak >nul
    )
)

echo.
echo   +--------------------------------------------------+
echo   ^| Snapgent is now running.                         ^|
echo   ^| Target Editors: VS Code and Zed Editor           ^|
echo   ^| Keep this window open while you use the agent.   ^|
echo   +--------------------------------------------------+
echo.

if defined PY (
    %PY% "%~dp0bridge.py"
) else (
    if exist "%~dp0bridge.exe" (
        "%~dp0bridge.exe"
    ) else (
        echo ERROR: Neither Python 3 nor bridge.exe was found.
        pause
        exit /b 1
    )
)

pause
