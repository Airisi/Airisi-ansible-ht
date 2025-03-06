#!/bin/bash

# 获取脚本所在目录
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR" || exit 1

# 判断是否传入主机参数
if [ -z "$1" ]; then
    echo "错误: 请传入主机参数。"
    echo "用法: $0 <主机名>"
    exit 1
fi

# 执行 summary_report_generator.sh 脚本，并传入主机参数
./summary_report_generator.sh "$1"
