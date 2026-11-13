@echo off
chcp 65001 >nul
title xMacro - Key Spam 50ms
cd /d "%~dp0"
python "%~dp0HoldKeyEngine.py" %*
if errorlevel 1 pause
