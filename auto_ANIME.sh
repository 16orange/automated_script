#!/bin/bash

#此为qBittorrent “Torrent 完成时运行外部程序” 专用sh脚本
#配合rss订阅，可自动分类ANi组发布的动画到子目录

# 设置下载目录和目标目录
download_dir="/mnt/sdb2/ANIME/tmp"
base_target_dir="/mnt/sdb2/ANIME"

# 创建目标目录的函数
copy_to_target_dir() {
    local file=$1
    local anime_name=$2
    local year=$3
    local quarter=$4

    # 动态创建季度目录和动画子目录
    target_dir="$base_target_dir/${year}${quarter}/${anime_name}"
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
        echo "Created directory $target_dir"
    fi

    # 复制文件
    cp "$file" "$target_dir"
    echo "Copied $(basename "$file") to $target_dir"
}

# 获取季度
get_quarter() {
    local episode_count=$1
    local week_per_episode=7
    local episodes_per_quarter=12

    # 找到季度起始集数
    start_episode=$(( ((episode_count - 1) / episodes_per_quarter) * episodes_per_quarter + 1 ))

    # 计算需要推算的天数
    episode_days=$(( (episode_count - start_episode) * week_per_episode ))

    # 获取当前时间
    current_time=$(date +%s)
    target_time=$(( current_time - episode_days * 86400 ))  # 转换为秒
    target_date=$(date -d @"$target_time" +"%Y-%m-%d")

    target_year=$(echo "$target_date" | cut -d '-' -f 1)
    target_month=$(echo "$target_date" | cut -d '-' -f 2)

    # 根据月份获取季度
    case $target_month in
        12|01|02) echo "$target_year Q1" ;;
        03|04|05) echo "$target_year Q2" ;;
        06|07|08) echo "$target_year Q3" ;;
        09|10|11) echo "$target_year Q4" ;;
    esac
}

# 遍历下载目录中的文件
for file in "$download_dir"/*; do
    [ -f "$file" ] || continue  # 跳过非文件

    # 提取动画名称和集数
    anime_name=$(basename "$file" | sed -E 's/^\[ANi\] ([^-]+) - .*/\1/')
    episode_count=$(basename "$file" | sed -E 's/.* - ([0-9]+) .*/\1/')

    # 验证集数是否为数字
    if ! [[ "$episode_count" =~ ^[0-9]+$ ]]; then
        echo "Error: Unable to extract episode number from $(basename "$file")"
        continue
    fi

    # 处理特殊字符
    anime_name=$(echo "$anime_name" | sed 's/[\/:*?"<>|]/-/g' | sed 's/ *$//')

    echo "Processing $anime_name, Episode: $episode_count..."

    # 获取季度和年份信息
    season_info=$(get_quarter "$episode_count")
    start_year=$(echo "$season_info" | cut -d ' ' -f 1)
    quarter=$(echo "$season_info" | cut -d ' ' -f 2)

    # 复制文件到目标目录
    copy_to_target_dir "$file" "$anime_name" "$start_year" "$quarter"
done

echo "All files have been organized."

