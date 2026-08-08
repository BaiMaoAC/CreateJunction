@echo off
cls
setlocal enabledelayedexpansion

:: ================== 定义 ANSI 颜色 ==================
for /F %%A in ('echo prompt $E ^| cmd') do set "ESC=%%A"
set "RESET=%ESC%[0m"
set "CYAN=%ESC%[96m"
set "YELLOW=%ESC%[93m"
set "GREEN=%ESC%[92m"
set "RED=%ESC%[91m"
set "MAGENTA=%ESC%[95m"
set "BOLD=%ESC%[1m"

:: ================== 请求管理员权限 ==================
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: ================== 主程序 ==================
title 创建传送门
echo %CYAN%╔═══════════════════════════════════════════════╗%RESET%
echo %CYAN%║           %BOLD%🔗 创建目录传送门%RESET%%CYAN%                   ║%RESET%
echo %CYAN%╚═══════════════════════════════════════════════╝%RESET%
echo.
echo %YELLOW%请输入要在其中创建传送门的目录路径：%RESET%
set /p workdir=
if "!workdir!"=="" exit /b
if not exist "!workdir!" (
    echo %RED%错误：目录不存在！%RESET%
    timeout /t 2 >nul
    exit /b
)

echo.
echo %YELLOW%当前目录：%RESET%%BOLD%!workdir!%RESET%
echo.
echo %GREEN%请将目标文件夹拖入此窗口，然后按回车：%RESET%
set /p target=
if "!target!"=="" exit /b

:: ---------- 安全检查 ----------
set "target_abs=!target!"
set "workdir_abs=!workdir!"
if "!target_abs:~-1!"=="\" set "target_abs=!target_abs:~0,-1!"
if "!workdir_abs:~-1!"=="\" set "workdir_abs=!workdir_abs:~0,-1!"

if /i "!target_abs!"=="!workdir_abs!" (
    echo %RED%错误：目标路径与当前目录相同，不能创建指向自己的链接。%RESET%
    timeout /t 3 >nul
    exit /b
)

echo !target_abs! | findstr /i /b "!workdir_abs!\\" >nul
if !errorlevel! equ 0 (
    echo %RED%错误：目标路径是当前目录的子目录，不能创建指向内部的链接。%RESET%
    timeout /t 3 >nul
    exit /b
)

:: ---------- 提取目标文件夹名称 ----------
for %%i in ("!target_abs!") do set "foldername=%%~nxi"
set "linkpath=!workdir!\!foldername!"

:: ---------- 处理重名 ----------
if exist "!linkpath!" (
    echo %YELLOW%警告：当前目录已存在同名项目 "%foldername%"%RESET%
    choice /C RC /M "%YELLOW%按 R 删除并替换，按 C 取消操作%RESET%"
    if errorlevel 2 (
        echo 操作已取消。
        exit /b
    )
    if errorlevel 1 (
        echo 正在删除原有项目...
        rmdir /s /q "!linkpath!"
        if errorlevel 1 (
            echo %RED%删除失败，请关闭占用该文件夹的程序。%RESET%
            timeout /t 3 >nul
            exit /b
        )
        echo 原有项目已删除。
    )
)

:: ---------- 创建 Junction ----------
mklink /J "!linkpath!" "!target!"
if %errorlevel% equ 0 (
    echo.
    echo %GREEN%╔═══════════════════════════════════════════════╗%RESET%
    echo %GREEN%║           ✅ 创建成功！                        ║%RESET%
    echo %GREEN%╚═══════════════════════════════════════════════╝%RESET%
    echo.
    echo %MAGENTA%链接位置：%RESET%%BOLD%!linkpath!%RESET%
    echo %MAGENTA%指向目标：%RESET%%BOLD%!target!%RESET%
    echo.
    echo 窗口将在 3 秒后自动关闭...
    explorer /select, "!linkpath!"
    timeout /t 3 >nul
) else (
    echo %RED%创建失败，请确认目标路径存在，且有管理员权限。%RESET%
    timeout /t 3 >nul
)
exit /b