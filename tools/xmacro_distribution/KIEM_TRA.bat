@echo off
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Check-xMacro.ps1" %*
echo.
echo Gui lai noi dung xMacro-check.txt de kiem tra dung client dang chay.
pause
