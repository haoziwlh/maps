@echo off
chcp 65001 >/dev/null
title WC3 地图测试工具
echo.
echo ============================================================
echo   WC3 地图测试工具 - qingxiaoruins
echo ============================================================
echo.

:: ── 1. 下载最新地图 ──────────────────────────────────────────
echo [1/4] 正在下载最新地图...
set MAP_URL=https://github.com/haoziwlh/maps/raw/main/dist/qingxiaoruins.w3x
set MAP_FILE=%TEMP%\qingxiaoruins.w3x

powershell -Command "try { Invoke-WebRequest -Uri '%MAP_URL%' -OutFile '%MAP_FILE%' -UseBasicParsing; Write-Host '  下载成功' } catch { Write-Host '  下载失败:' $_.Exception.Message; exit 1 }"
if errorlevel 1 (
    echo.
    echo [错误] 无法下载地图，请检查网络连接
    pause & exit /b 1
)
echo   文件大小: 
for %%A in ("%MAP_FILE%") do echo     %%~zA bytes

:: ── 2. 找 WC3 安装目录 ───────────────────────────────────────
echo.
echo [2/4] 查找 Warcraft III 安装目录...
set WC3_EXE=
set WC3_DIR=

for %%P in (
    "C:\Program Files (x86)\Warcraft III"
    "C:\Program Files\Warcraft III"
    "D:\Warcraft III"
    "D:\Games\Warcraft III"
    "E:\Warcraft III"
    "E:\Games\Warcraft III"
) do (
    if exist "%%~P\Warcraft III.exe" (
        set WC3_DIR=%%~P
        set WC3_EXE=%%~P\Warcraft III.exe
        goto :found_wc3
    )
    if exist "%%~P\war3.exe" (
        set WC3_DIR=%%~P
        set WC3_EXE=%%~P\war3.exe
        goto :found_wc3
    )
)

:: 注册表查找
for /f "tokens=2*" %%A in ('reg query "HKLM\SOFTWARE\WOW6432Node\Blizzard Entertainment\Warcraft III" /v InstallPath 2^>nul') do set WC3_DIR=%%B
if defined WC3_DIR (
    if exist "%WC3_DIR%\Warcraft III.exe" set WC3_EXE=%WC3_DIR%\Warcraft III.exe
    if exist "%WC3_DIR%\war3.exe" set WC3_EXE=%WC3_DIR%\war3.exe
    if defined WC3_EXE goto :found_wc3
)

echo   [警告] 未自动找到 WC3，请手动输入安装路径:
echo   例如: C:\Program Files (x86)\Warcraft III
set /p WC3_DIR=  路径: 
if not exist "%WC3_DIR%\Warcraft III.exe" if not exist "%WC3_DIR%\war3.exe" (
    echo   [错误] 路径无效
    pause & exit /b 1
)
if exist "%WC3_DIR%\Warcraft III.exe" set WC3_EXE=%WC3_DIR%\Warcraft III.exe
if exist "%WC3_DIR%\war3.exe" set WC3_EXE=%WC3_DIR%\war3.exe

:found_wc3
echo   找到: %WC3_EXE%

:: 检查版本
set WC3_VERSION=未知
for /f "tokens=*" %%V in ('powershell -Command "(Get-Item '%WC3_EXE%').VersionInfo.FileVersion" 2^>nul') do set WC3_VERSION=%%V
echo   版本: %WC3_VERSION%

:: ── 3. 复制地图到 Maps 目录 ──────────────────────────────────
echo.
echo [3/4] 安装地图...
set MAPS_DIR=%WC3_DIR%\Maps
if not exist "%MAPS_DIR%" mkdir "%MAPS_DIR%"

copy /Y "%MAP_FILE%" "%MAPS_DIR%\qingxiaoruins.w3x" >/dev/null
echo   已复制到: %MAPS_DIR%\qingxiaoruins.w3x

:: ── 4. 清理旧日志并启动 WC3 ─────────────────────────────────
echo.
echo [4/4] 启动 Warcraft III...
echo.
echo ============================================================
echo   请在游戏中:
echo   1. 进入 「自定义游戏」
echo   2. 找到并双击 「qingxiaoruins」
echo   3. 记录报错信息（截图或抄下来）
echo   4. 关闭游戏后，本窗口会收集日志
echo ============================================================
echo.

:: 清理旧的 WC3 日志
set LOG_DIR=%USERPROFILE%\Documents\Warcraft III\Logs
if not exist "%LOG_DIR%" set LOG_DIR=%WC3_DIR%\Logs
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >/dev/null 2>&1

:: 启动 WC3 并等待退出
start "" "%WC3_EXE%"
echo   WC3 已启动，等待游戏关闭...
echo   （关闭游戏后继续）
echo.

:wait_loop
timeout /t 3 /nobreak >/dev/null
tasklist /fi "imagename eq Warcraft III.exe" 2>/dev/null | find /i "Warcraft III.exe" >/dev/null
if not errorlevel 1 goto :wait_loop
tasklist /fi "imagename eq war3.exe" 2>/dev/null | find /i "war3.exe" >/dev/null
if not errorlevel 1 goto :wait_loop

:: ── 收集日志 ─────────────────────────────────────────────────
echo.
echo ============================================================
echo   游戏已关闭，收集诊断信息...
echo ============================================================

set REPORT=%USERPROFILE%\Desktop\wc3_report.txt
echo WC3 地图测试报告 > "%REPORT%"
echo 时间: %DATE% %TIME% >> "%REPORT%"
echo WC3路径: %WC3_EXE% >> "%REPORT%"
echo WC3版本: %WC3_VERSION% >> "%REPORT%"
echo. >> "%REPORT%"

echo === WC3 日志文件 === >> "%REPORT%"
if exist "%LOG_DIR%" (
    echo 日志目录: %LOG_DIR% >> "%REPORT%"
    for %%F in ("%LOG_DIR%\*.txt" "%LOG_DIR%\*.log") do (
        echo. >> "%REPORT%"
        echo --- %%F --- >> "%REPORT%"
        type "%%F" >> "%REPORT%" 2>/dev/null
    )
) else (
    echo 未找到日志目录 >> "%REPORT%"
)

echo. >> "%REPORT%"
echo === Warcraft III 目录文件 === >> "%REPORT%"
dir "%WC3_DIR%" >> "%REPORT%" 2>/dev/null

echo. >> "%REPORT%"
echo === 系统信息 === >> "%REPORT%"
systeminfo | findstr /C:"OS" /C:"内存" /C:"Memory" >> "%REPORT%" 2>/dev/null

echo.
echo 报告已保存到桌面: wc3_report.txt
echo 请将此文件发给开发者
echo.
pause
