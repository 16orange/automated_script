@echo off
setlocal enabledelayedexpansion

rem ��ʾ�û�����ǰ׺
set /p prefix="�����뼾�ȣ��� S01 �� S02����"

set "counter=1"

rem ������ǰĿ¼�µ������ļ�
for %%F in (*) do (
    rem ����ļ���׺�Ƿ�Ϊ .bat
    if /i not "%%~xF"==".bat" (
        rem ��ʽ������Ϊ��λ��
        set "num=00!counter!"
        set "num=!num:~-2!"
        
        rem �������ļ�
        ren "%%F" "!prefix!E!num!%%~xF"
        
        set /a counter+=1
    )
)

endlocal
