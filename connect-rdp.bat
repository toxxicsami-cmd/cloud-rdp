@echo off
title Cloud RDP Connect
echo ============================
echo   CLOUD RDP CONNECT
echo ============================
echo.

if not exist "%LOCALAPPDATA%\cloudflared.exe" (
    echo Downloading cloudflared...
    powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe' -OutFile \"$env:LOCALAPPDATA\cloudflared.exe\""
)

set /p TUNNEL="Paste tunnel hostname (xxxx.trycloudflare.com): "
if "%TUNNEL%"=="" (
    echo No hostname given.
    pause
    exit /b 1
)

if "%TUNNEL:~0,8%"=="https://" set TUNNEL=%TUNNEL:~8%

echo.
echo Opening tunnel to %TUNNEL% on localhost:13389 ...
start "cloudflared-tunnel" "%LOCALAPPDATA%\cloudflared.exe" access tcp --hostname %TUNNEL% --url localhost:13389

timeout /t 5 /nobreak >nul
echo Launching mstsc...
start mstsc /v:localhost:13389

echo.
echo Tunnel window must stay open while you work.
pause
