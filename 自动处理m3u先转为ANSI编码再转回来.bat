@echo off
setlocal enabledelayedexpansion

set "inputFile=input.m3u"  rem �����ļ�·��
set "outputFile=output.m3u" rem ����ļ�·��

rem �������ļ�
echo. > "%outputFile%"

for /f "usebackq delims=" %%a in ("%inputFile%") do (
    set "line=%%a"
    if "!line!" neq "" (
        echo !line! | findstr /r "^rtp://" >nul
        if !errorlevel! == 0 (
            rem �滻 RTP ��ַ
            set "line=http://10.1.1.1:8012/rtp/!line:rtp://=!"
            echo !line!\ >> "%outputFile%"
        ) else (
            echo !line! >> "%outputFile%"
        )
    )
)

echo ��ɣ�����ļ�Ϊ��%outputFile%
pause