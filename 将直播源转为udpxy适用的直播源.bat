@echo off
setlocal enabledelayedexpansion

REM 自动将网上找到的m3u直播源，方便地转为udpxy代理来看的自动脚本
REM 为解决中文乱码问题，m3u文件要先转为ANSI编码，执行完脚本后再转回UFT-8

set "inputFile=input.m3u"  rem 输入文件路径
set "outputFile=output.m3u" rem 输出文件路径

rem 清空输出文件
echo. > "%outputFile%"

for /f "usebackq delims=" %%a in ("%inputFile%") do (
    set "line=%%a"
    if "!line!" neq "" (
        echo !line! | findstr /r "^rtp://" >nul
        if !errorlevel! == 0 (
            rem 替换 RTP 地址
            set "line=http://10.1.1.1:8012/rtp/!line:rtp://=!"
            echo !line!\ >> "%outputFile%"
        ) else (
            echo !line! >> "%outputFile%"
        )
    )
)

echo 完成！输出文件为：%outputFile%
pause
