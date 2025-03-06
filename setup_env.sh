#!/bin/bash

# 1. 获取脚本所在目录
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# 2. 创建 ansible 配置软链接（仅在 ~/.ansible.cfg 不存在时创建）
if [ ! -e ~/.ansible.cfg ]; then
    ln -s "${SCRIPT_DIR}/config/.ansible.cfg" ~/.ansible.cfg
    echo "创建 ~/.ansible.cfg 软链接"
else
    echo "~/.ansible.cfg 已存在，跳过创建"
fi

# 3. 安装 ansible==2.9.0（仅在系统未安装 ansible 时安装）
if ! command -v ansible &>/dev/null; then
    echo "安装 ansible==2.9.0..."
    pip3 install ansible==2.9.0
else
    echo "ansible 已安装，跳过安装"
fi

# 4. 生成 SSH 密钥对（仅在默认 SSH 公钥不存在时生成）
if [ ! -f ~/.ssh/id_rsa.pub ]; then
    echo "生成 SSH 密钥对..."
    ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
else
    echo "SSH 密钥已存在，跳过生成"
fi

# 5. 从 config/hosts 提取有效 IP 地址（忽略空行、注释和分组标识）
HOST_FILE="${SCRIPT_DIR}/config/hosts"
ips=()

if [ -f "$HOST_FILE" ]; then
    while IFS= read -r line; do
        trimmed=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [[ -z "$trimmed" ]] || [[ "$trimmed" =~ ^# ]] || [[ "$trimmed" =~ ^\[.*\]$ ]]; then
            continue
        fi
        ips+=("$trimmed")
    done < "$HOST_FILE"
else
    echo "错误：hosts 文件 ${HOST_FILE} 不存在！"
    exit 1
fi

# 6. 分发 SSH 公钥到目标主机（使用 sshpass，密码为 'ht123'）
for ip in "${ips[@]}"; do
    echo "分发 SSH 公钥到 ${ip} ..."
    sshpass -p 'ht123' ssh-copy-id -o StrictHostKeyChecking=no root@"$ip"
done

echo "配置完成"

