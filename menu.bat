@echo off
chcp 65001 >nul
cd /d "%~dp0"
title Xray Fragment Fingerprint Manager
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0menu.ps1"
pause
