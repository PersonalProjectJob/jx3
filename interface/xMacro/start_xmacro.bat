@echo off
chcp 65001 >nul
title xMacro - Key Spam 50ms
cd /d "%~dp0"
if exist "%~dp0KeySpam.exe" (
  "%~dp0KeySpam.exe" %*
  if errorlevel 1 pause
  exit /b
)
where py >nul 2>nul
if not errorlevel 1 (
  py -3 "%~dp0Tools\KeySpam\engine.py" %*
  if errorlevel 1 pause
  exit /b
)
where python >nul 2>nul
if not errorlevel 1 (
  python "%~dp0Tools\KeySpam\engine.py" %*
  if errorlevel 1 pause
  exit /b
)
echo LOI: Thieu KeySpam.exe. Hay giai nen lai goi xMacro day du.
echo Neu dung ma nguon, can Python 3 de chay Tools\KeySpam\engine.py.
pause
exit /b 1
