#!/bin/sh

# 获取脚本所在目录的绝对路径
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
DOMAIN_LIST="$SCRIPT_DIR/domain_list.txt"
BLOCKED_INFO="$SCRIPT_DIR/blocked_domains_info.txt"
IP_DOMAIN_MAP="$SCRIPT_DIR/ip_domain_map.txt"

create_domain_list() {
    cat > "$DOMAIN_LIST" << EOF
# 域名列表文件
# 每行输入一个要屏蔽的域名
# 例如:
# example.com
# example.org
# example.net

# 脚本功能介绍:
# 1. 读取此文件中的域名列表
# 2. 解析每个域名的IP地址
# 3. 使用iptables屏蔽这些IP地址
# 4. 每24小时自动重复执行一次
# 5. 显示距离下次执行的倒计时

# 请在下方添加您要屏蔽的域名:

EOF
    echo "已创建 $DOMAIN_LIST 文件,请编辑该文件添加要屏蔽的域名。"
    echo "添加完成后,请重新运行此脚本。"
    exit 0
}

block_domains() {
    # 检查域名列表文件是否存在
    if [ ! -f "$DOMAIN_LIST" ]; then
        echo "错误：$DOMAIN_LIST 文件不存在,正在创建..."
        create_domain_list
    fi

    # 检查文件是否为空或只包含注释
    if ! grep -q '^[^#]' "$DOMAIN_LIST"; then
        echo "警告：$DOMAIN_LIST 文件为空或只包含注释。"
        echo "请编辑文件添加要屏蔽的域名,然后重新运行此脚本。"
        exit 1
    fi

    # 创建自定义链（如果不存在）
    iptables -N DOMAIN_BLOCK 2>/dev/null
    iptables -F DOMAIN_BLOCK

    # 在FORWARD链中引用自定义链（如果尚未添加）
    iptables -C FORWARD -j DOMAIN_BLOCK 2>/dev/null || iptables -A FORWARD -j DOMAIN_BLOCK

    # 创建IPv6自定义链（如果不存在）
    ip6tables -N DOMAIN_BLOCK 2>/dev/null
    ip6tables -F DOMAIN_BLOCK

    # 在IPv6 FORWARD链中引用自定义链（如果尚未添加）
    ip6tables -C FORWARD -j DOMAIN_BLOCK 2>/dev/null || ip6tables -A FORWARD -j DOMAIN_BLOCK

    # 清空已屏蔽域名信息文件
    echo "# 已屏蔽的域名和对应IP地址" > "$BLOCKED_INFO"
    echo "# 更新时间: $(date)" >> "$BLOCKED_INFO"
    echo "" >> "$BLOCKED_INFO"

    # 清空IP-域名映射文件
    echo "# IP地址和对应的域名映射" > "$IP_DOMAIN_MAP"
    echo "# 更新时间: $(date)" >> "$IP_DOMAIN_MAP"
    echo "" >> "$IP_DOMAIN_MAP"

    # 创建临时文件来存储新的IP-域名映射
    TEMP_IP_DOMAIN_MAP=$(mktemp)

    # 读取现有的IP-域名映射，将所有条目标记为过时
    if [ -f "$IP_DOMAIN_MAP" ]; then
        sed 's/^/过时 /' "$IP_DOMAIN_MAP" > "$TEMP_IP_DOMAIN_MAP"
    fi

    # 定义多个DNS服务器
    DNS_SERVERS="223.5.5.5 223.6.6.6 114.114.114.114 114.114.115.115 119.29.29.29 180.76.76.76"

    # 读取域名列表并处理每个域名
    while read -r domain || [ -n "$domain" ]; do
        # 跳过注释和空行
        [[ "$domain" =~ ^#.*$ || -z "$domain" ]] && continue
        
        echo "正在处理域名: $domain"
        
        # 使用多个DNS服务器尝试解析域名（IPv4和IPv6）
        ips=""
        ip6s=""
        for dns in $DNS_SERVERS; do
            ips=$(nslookup -type=A $domain $dns | awk '/^Address: / && !/^Address: '$dns'$/ {print $2}')
            ip6s=$(nslookup -type=AAAA $domain $dns | awk '/has AAAA address/ {print $NF}')
            if [ -n "$ips" ] || [ -n "$ip6s" ]; then
                echo "使用DNS服务器 $dns 成功解析域名"
                break
            fi
        done

        if [ -z "$ips" ] && [ -z "$ip6s" ]; then
            echo "无法解析域名 $domain 的IP地址"
            continue
        fi

        echo "域名 $domain 的IPv4地址是:"
        echo "$ips"
        echo "域名 $domain 的IPv6地址是:"
        echo "$ip6s"

        # 记录到已屏蔽域名信息文件
        echo "域名: $domain" >> "$BLOCKED_INFO"
        echo "IPv4地址:" >> "$BLOCKED_INFO"

        # 使用iptables屏蔽所有IPv4
        for ip in $ips; do
            iptables -C DOMAIN_BLOCK -s $ip -j DROP 2>/dev/null
            if [ $? -ne 0 ]; then
                iptables -A DOMAIN_BLOCK -s $ip -j DROP
                echo "已屏蔽IPv4地址 $ip"
            else
                echo "IPv4地址 $ip 已经被屏蔽"
            fi
            echo "- $ip" >> "$BLOCKED_INFO"
            
            # 更新IP-域名映射文件
            sed -i "/^过时 $ip /d" "$TEMP_IP_DOMAIN_MAP"
            echo "$ip $domain" >> "$TEMP_IP_DOMAIN_MAP"
        done

        echo "IPv6地址:" >> "$BLOCKED_INFO"

        # 使用ip6tables屏蔽所有IPv6
        for ip6 in $ip6s; do
            ip6tables -C DOMAIN_BLOCK -s $ip6 -j DROP 2>/dev/null
            if [ $? -ne 0 ]; then
                ip6tables -A DOMAIN_BLOCK -s $ip6 -j DROP
                echo "已屏蔽IPv6地址 $ip6"
            else
                echo "IPv6地址 $ip6 已经被屏蔽"
            fi
            echo "- $ip6" >> "$BLOCKED_INFO"
            
            # 更新IP-域名映射文件
            sed -i "/^过时 $ip6 /d" "$TEMP_IP_DOMAIN_MAP"
            echo "$ip6 $domain" >> "$TEMP_IP_DOMAIN_MAP"
        done
        echo "" >> "$BLOCKED_INFO"
    done < "$DOMAIN_LIST"

    # 将更新后的IP-域名映射写入文件
    echo "# IP地址和对应的域名映射" > "$IP_DOMAIN_MAP"
    echo "# 更新时间: $(date)" >> "$IP_DOMAIN_MAP"
    echo "" >> "$IP_DOMAIN_MAP"
    cat "$TEMP_IP_DOMAIN_MAP" >> "$IP_DOMAIN_MAP"

    # 删除临时文件
    rm "$TEMP_IP_DOMAIN_MAP"

    # 保存iptables规则
    iptables-save > /etc/iptables.rules

    # 保存ip6tables规则
    ip6tables-save > /etc/ip6tables.rules

    # 重新加载防火墙
    /etc/init.d/firewall reload

    echo "所有域名的IPv4和IPv6屏蔽操作完成"
    echo "已屏蔽的域名和IP信息已保存到 $BLOCKED_INFO"
}

# 倒计时函数
countdown() {
    local remaining=$1
    while [ $remaining -gt 0 ]; do
        hours=$((remaining / 3600))
        minutes=$(( (remaining % 3600) / 60 ))
        seconds=$((remaining % 60))
        printf "\r下次执行还剩: %02d:%02d:%02d" $hours $minutes $seconds
        sleep 10
        remaining=$((remaining - 10))
    done
    echo
}

# 主循环
while true; do
    block_domains
    echo "等待24小时后再次执行..."
    countdown 86400  # 24小时 = 86400秒
done