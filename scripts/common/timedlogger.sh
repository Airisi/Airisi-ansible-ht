#!/bin/bash

# 自动切换到脚本所在目录
cd "$(dirname "$0")" || { echo "无法进入脚本目录"; exit 1; }

# 判断 CMD 是否输入，如果未设置则退出
if [ -z "$1" ]; then
    echo "Usage: $0 <command>"
    exit 1
fi

# 将所有参数作为命令存入变量 CMD
CMD="$*"

# 获取当前格式化的时间戳
start_timestamp=$(date +'%Y_%m_%d-%Hh_%Mm_%Ss')

# 设置日志文件路径
LOG_10_FILE="time10s-${start_timestamp}.log"
LOG_60_FILE="time60s-${start_timestamp}.log"
LOG_100_FILE="time100s-${start_timestamp}.log"
LOG_1H_FILE="time1h-${start_timestamp}.log"

# 对齐到下一个整10秒时刻
current_epoch=$(date +%s)
next_target=$(( ((current_epoch / 10) + 1) * 10 ))
sleep_time=$(( next_target - current_epoch ))
echo "等待对齐到整10秒时刻，睡眠 ${sleep_time} 秒..."
sleep $sleep_time

# 记录基准时间（对齐后的起始时间）
base_time=$(date +%s)
n=1

while true; do
    # 计算下一个目标时间（基准时间 + n×10秒）
    target_time=$(( base_time + n * 10 ))

    # 获取当前时间，若未达到目标，则睡眠相差时间
    current_epoch=$(date +%s)
    if [ $current_epoch -lt $target_time ]; then
        sleep_time=$(( target_time - current_epoch ))
        sleep $sleep_time
    fi

    timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    # 执行传入的命令并获取输出
    cmd_output=$(eval "$CMD")

    OUTPUT="${timestamp},${cmd_output}"

    # 每个整10秒的结果都记录到 10s 日志文件
    echo "$OUTPUT" >> "$LOG_10_FILE"

    # 如果 n 是 6 的倍数，则记录到 60s 日志（即每 60 秒）
    if (( n % 6 == 0 )); then
        echo "$OUTPUT" >> "$LOG_60_FILE"
    fi

    # 如果 n 是 10 的倍数，则记录到 100s 日志
    if (( n % 10 == 0 )); then
        echo "$OUTPUT" >> "$LOG_100_FILE"
    fi

    # 如果 n 是 360 的倍数，则记录到 1 小时日志（360×10 = 3600秒）
    if (( n % 360 == 0 )); then
        echo "$OUTPUT" >> "$LOG_1H_FILE"
    fi

    n=$(( n + 1 ))
done
