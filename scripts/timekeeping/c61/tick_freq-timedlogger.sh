#!/bin/bash

# 自动切换到脚本所在目录
cd "$(dirname "$0")" || { echo "无法进入脚本目录"; exit 1; }

# 设置日志文件路径，使用 frequency 值作为后缀
LOF_FILE="time.log"
LOG_10_FILE="time10s.csv"
LOG_60_FILE="time60s.csv"
LOG_100_FILE="time100s.csv"
LOG_1H_FILE="time1h.csv"

# 启动 ntp 服务
systemctl start ntp

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

    # 获取当前格式化的时间戳
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    # 执行 sntp 测试
    adjtimex_output=$(adjtimex -p)

    # 记录原始输出日志
    echo "sntp_output" >> "$LOF_FILE"

    # 提取所需信息
    tick_output=$(echo "$adjtimex_output" | grep "tick" | awk '{print $2}')
    freq_output=$(echo "$adjtimex_output" | grep "frequency" | awk '{print $2}')

    # 获取温度信息
    temp=$(cat /sys/class/thermal/thermal_zone0/temp)

    # 整合输出内容
    OUTPUT="${timestamp},${tick_output},${freq_output},${temp}"

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
