@echo off
setlocal enabledelayedexpansion

REM 获取当前目录
set "parentDir=%cd%"

echo 当前路径: %parentDir%

echo 开始移动文件...

REM 遍历所有子目录和子目录的子目录
for /r %%D in (.) do (
    if exist "%%D\*" (
        echo 发现目录: "%%D"
        for %%F in ("%%D\*") do (
            echo 移动文件: "%%F"
            move "%%F" "%parentDir%" 2>nul
            if errorlevel 1 (
                echo 移动失败: "%%F"
            )
        )
    )
)

echo 完成！
pause
