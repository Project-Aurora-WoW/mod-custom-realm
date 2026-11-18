@echo off
REM ============================================================
REM Инсталлер клиентской части реалма «Эхо Пустоты»
REM Двойной клик запускает GUI-инсталлер (install-client.ps1).
REM ============================================================
title Эхо Пустоты — установка клиента
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-client.ps1"
if errorlevel 1 pause