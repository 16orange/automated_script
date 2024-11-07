#!/bin/bash

#运行sh /mnt/nvme0n1p4/sh/nhentai_DL.sh

# 提示用户输入漫画的 ID
read -p "请输入漫画的 ID: " manga_id

# 检查用户是否输入了 ID
if [[ -z "$manga_id" ]]; then
  echo "错误: 漫画 ID 不能为空！"
  exit 1
fi

# 运行 docker 命令下载漫画
echo "正在下载漫画 ID: $manga_id ..."
docker run --rm -it \
  -v /mnt/sda/docker/lanraragi/content/nhentai:/output \
  -v /mnt/sda/docker/nhentai/:/root/.nhentai \
  ricterz/nhentai --id "$manga_id"

# 检查下载是否成功
if [[ $? -ne 0 ]]; then
  echo "下载失败！请检查漫画 ID 是否正确。"
  exit 1
fi

# 查找唯一的下载文件夹（排除所有 .zip 文件）
downloaded_folder=$(find /mnt/sda/docker/lanraragi/content/nhentai -mindepth 1 -maxdepth 1 -type d ! -name "*.zip" | head -n 1)

# 如果没有找到文件夹，说明下载失败
if [[ -z "$downloaded_folder" ]]; then
  echo "下载的文件夹不存在！"
  exit 1
fi

# 执行压缩操作，使用 bsdtar 生成 .zip 文件
echo "正在压缩下载的内容..."
bsdtar -cf "${downloaded_folder}.zip" -C "$(dirname "$downloaded_folder")" "$(basename "$downloaded_folder")"

# 检查压缩是否成功
if [[ $? -eq 0 ]]; then
  echo "压缩成功！生成的 ZIP 文件路径: ${downloaded_folder}.zip"
else
  echo "压缩失败！"
  exit 1
fi

# 删除下载的文件夹
echo "正在删除下载的文件夹..."
rm -rf "$downloaded_folder"

# 确认删除是否成功
if [[ $? -eq 0 ]]; then
  echo "文件夹删除成功！"
else
  echo "文件夹删除失败！"
  exit 1
fi

