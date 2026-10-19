@echo off
chcp 65001 >nul
:: 检查管理员权限，若无则自动提权请求
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 正在获取管理员权限...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\disable-windows-update.ps1"
echo.
echo 按任意键退出...
pause >nul
