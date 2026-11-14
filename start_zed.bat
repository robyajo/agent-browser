@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title Snapgent Connector for Zed Editor
cd /d "%~dp0"

if not exist "%~dp0logs" mkdir "%~dp0logs" >nul 2>nul
set "LOGFILE=%~dp0logs\start_zed.log"

echo ========================================================
echo   ⚡ Snapgent Connector for Zed Editor (Windows)
echo   Support: DeepSeek, Qwen, Claude, ChatGPT -^> Zed Editor
echo ========================================================
echo.

REM 1. Find Python 3.9+
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

if not defined PY (
    echo   ERROR: Python 3.9 or newer was not found.
    echo   Please install Python 3 from https://www.python.org/downloads/
    echo   (Make sure to check "Add python.exe to PATH" during installation)
    echo.
    pause
    exit /b 1
)

echo   [1/4] Python found:
%PY% --version
echo.

REM 2. Check websockets
echo   [2/4] Checking websockets dependency...
%PY% -c "import websockets" >nul 2>nul
if %errorlevel% neq 0 (
    echo         Installing websockets...
    %PY% -m pip install websockets
    if !errorlevel! neq 0 (
        echo   ERROR: Failed to install websockets.
        pause
        exit /b 1
    )
)
echo         websockets library ready.
echo.

REM 3. Configure MCP servers (Zed + VS Code)
echo   [3/4] Configuring MCP servers (Zed + VS Code)...
%PY% "%~dp0setup-config.py"
echo.

REM 4. Check ports 17613 and 17614
echo   [4/4] Checking ports 17613 and 17614...
for %%P in (17613 17614) do (
    for /f "tokens=5" %%a in ('netstat -aon ^| findstr :%%P ^| findstr LISTENING 2^>nul') do (
        echo         Stopping previous process (PID %%a) on port %%P...
        taskkill /F /T /PID %%a >nul 2>nul
        timeout /t 1 /nobreak >nul
    )
)
echo         Ports 17613 and 17614 ready.
echo.

echo   ========================================================
echo     🚀 Bridge ^& OpenAI Proxy Siap Dijalankan!
echo   --------------------------------------------------------
echo     Cara Pakai (Chat Langsung di Dalam Zed Editor):
echo     1. Buka tab chat di browser (biarkan terbuka):
echo        • DeepSeek : https://chat.deepseek.com atau
echo        • Qwen     : https://chat.qwen.ai
echo     2. Buka project Anda di Zed Editor.
echo     3. Buka panel Agent Zed (Ctrl + ?).
echo     4. Pilih model: DeepSeek Web (Snapgent Free) atau Qwen Web
echo     5. Chat langsung di Zed!
echo   --------------------------------------------------------
echo     Tekan Ctrl+C untuk menghentikan bridge.
echo   ========================================================
echo.

%PY% "%~dp0bridge.py"
pause
