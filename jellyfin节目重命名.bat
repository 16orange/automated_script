@echo off
setlocal enabledelayedexpansion

rem 提示用户输入前缀
set /p prefix="请输入季度（如 S01 或 S02）："

set "counter=1"

rem 遍历当前目录下的所有文件
for %%F in (*) do (
    rem 检查文件后缀是否为 .bat
    if /i not "%%~xF"==".bat" (
        rem 格式化数字为两位数
        set "num=00!counter!"
        set "num=!num:~-2!"
        
        rem 重命名文件
        ren "%%F" "!prefix!E!num!%%~xF"
        
        set /a counter+=1
    )
)

endlocal
