@echo off
setlocal enabledelayedexpansion

rem 从 https://github.com/Tzwcard/ChinaTelecom-GuangdongIPTV-RTP-List 下载的直播源处理脚本

set "inputFile=GuangdongIPTV_rtp_all.m3u"  rem 输入文件路径
set "outputFile=IPTV_udpxy.m3u" rem 输出文件路径

rem 清空输出文件
echo. > "%outputFile%"

for /f "usebackq delims=" %%a in ("%inputFile%") do (
    set "line=%%a"
    if "!line!" neq "" (
        echo !line! | findstr /r "^rtp://" >nul
        if !errorlevel! == 0 (
            rem 替换 RTP 地址
            set "line=http://10.1.1.1:8012/rtp/!line:rtp://=!"
            echo !line! >> "%outputFile%"
        ) else (
            echo !line! >> "%outputFile%"
        )
    )
)

echo 完成！输出文件为：%outputFile%
pause