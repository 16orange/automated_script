#!binsh

# 运行 sh /mnt/nvme0n1p4/sh/sda_smart.sh

while true; do
    clear  # 清除终端输出
    smartctl -a -d sat /dev/sda  # 执行 smartctl 命令
    sleep 10  # 等待 10 秒
done

