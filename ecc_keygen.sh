#!/bin/bash

# 提示用户输入密钥存储目录，默认为 $HOME/ecc_keys
read -p "请输入密钥存储目录（默认：$HOME/ecc_keys）: " KEY_DIR
KEY_DIR=${KEY_DIR:-"$HOME/ecc_keys"}  # 如果用户没有输入，使用默认值

# 提示用户输入 SSH 公钥注释的用户名（默认为 "user"）
read -p "请输入 SSH 公钥注释的用户名（默认：user）: " SSH_USER
SSH_USER=${SSH_USER:-"user"}  # 如果用户没有输入，使用默认值

# 获取系统主机名（用于填充注释中的 hostname）
HOSTNAME=$(hostname)

# 拼接 SSH 公钥注释
SSH_COMMENT="${SSH_USER}@${HOSTNAME}"

# 设置文件路径
PRIVATE_KEY_PATH="$KEY_DIR/private_key.pem"
ENCRYPTED_PRIVATE_KEY_PATH="$KEY_DIR/encrypted_private_key.pem"
PUBLIC_KEY_PATH="$KEY_DIR/public_key.pem"
SSH_PUB_KEY_PATH="$KEY_DIR/public_key.pub"

# 确保输出目录存在
mkdir -p "$KEY_DIR"

# 步骤 1：生成 ECDSA secp521r1 私钥，并保存为 PEM 格式
echo "生成 ECDSA secp521r1 私钥..."
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:secp521r1 -out "$PRIVATE_KEY_PATH"
if [ $? -ne 0 ]; then
  echo "错误：生成私钥失败。"
  exit 1
fi

# 步骤 2：对私钥进行 AES-256 加密，并保存加密后的私钥
echo "对私钥进行 AES-256 加密..."
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:secp521r1 -out "$ENCRYPTED_PRIVATE_KEY_PATH" -aes256
if [ $? -ne 0 ]; then
  echo "错误：加密私钥失败。"
  exit 1
fi

# 步骤 3：从私钥生成 ECDSA secp521r1 公钥，并保存为 PEM 格式
echo "生成 ECDSA secp521r1 公钥..."
openssl pkey -in "$PRIVATE_KEY_PATH" -pubout -out "$PUBLIC_KEY_PATH"
if [ $? -ne 0 ]; then
  echo "错误：生成公钥失败。"
  exit 1
fi

# 步骤 4：将 PEM 格式的公钥转换为 SSH 公钥格式并保存为 .pub 文件
echo "生成 SSH 公钥格式..."

# 将公钥转换为 DER 格式
openssl ec -in "$PUBLIC_KEY_PATH" -pubin -outform DER -out "$KEY_DIR/public_key.der"
if [ $? -ne 0 ]; then
  echo "错误：转换 PEM 到 DER 失败。"
  exit 1
fi

# 将 DER 格式的公钥进行 Base64 编码
base64 "$KEY_DIR/public_key.der" > "$KEY_DIR/public_key_base64.txt"
if [ $? -ne 0 ]; then
  echo "错误：Base64 编码 DER 公钥失败。"
  exit 1
fi

# 构建 SSH 公钥格式并添加用户提供的注释
BASE64_KEY=$(cat "$KEY_DIR/public_key_base64.txt")
SSH_PUB_KEY="ecdsa-sha2-nistp521 $BASE64_KEY $SSH_COMMENT"

# 将 SSH 公钥保存为 .pub 文件
echo "$SSH_PUB_KEY" > "$SSH_PUB_KEY_PATH"

if [ $? -eq 0 ]; then
  echo "转换成功！SSH 公钥已保存为：$SSH_PUB_KEY_PATH"
else
  echo "错误：保存 SSH 公钥失败。"
  exit 1
fi

# 删除临时生成的文件
echo "清理临时文件..."
rm "$KEY_DIR/public_key.der" "$KEY_DIR/public_key_base64.txt"

# 输出保留的文件
echo "密钥生成和转换过程完成，文件位于：$KEY_DIR"
echo "1. 加密私钥：$ENCRYPTED_PRIVATE_KEY_PATH"
echo "2. 原始公钥：$PUBLIC_KEY_PATH"
echo "3. SSH 公钥：$SSH_PUB_KEY_PATH"

