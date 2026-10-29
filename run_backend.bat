@echo off
title FluentTalk Backend Server
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\run_backend.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Backend da dung.
    pause
)
