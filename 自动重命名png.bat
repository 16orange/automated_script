@echo off
setlocal enabledelayedexpansion

rem 设置要处理的文件夹路径
set "folder=."

rem 初始化计数器
set count=1

rem 遍历当前文件夹中的所有 .png 文件
for %%f in (*.png) do (
    rem 重命名文件为数字.png
    ren "%%f" "!count!.png"
    set /a count+=1
)

