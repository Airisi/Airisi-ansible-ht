#!/bin/bash

# -------------------------------------------
# 1. 获取脚本所在目录并创建总输出目录
# -------------------------------------------
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
OUT_DIR="${SCRIPT_DIR}/report"

# 如果总输出目录不存在则创建
[ ! -d "$OUT_DIR" ] && mkdir -p "$OUT_DIR"

# -------------------------------------------
# 2. 定义结果目录和失败文件目录（必须存在，否则退出）
# -------------------------------------------
RESULT_DIR="${SCRIPT_DIR}/results"
FAILED_OUTPUT_DIR="${SCRIPT_DIR}/output"

[ ! -d "$RESULT_DIR" ] && { echo "结果目录不存在: $RESULT_DIR"; exit 1; }
[ ! -d "$FAILED_OUTPUT_DIR" ] && { echo "输出目录不存在: $FAILED_OUTPUT_DIR"; exit 1; }

# -------------------------------------------
# 3. 获取 SN 值（通过 htidctl 命令）
# -------------------------------------------
SN=$(htidctl | grep SN | awk '{print $2}' | tr -d '\r\n' | xargs)
# 若获取不到 SN，则使用默认值 "12345"
SN="${SN:-/}"

# -------------------------------------------
# 4. 处理日志文件，生成日志结果 CSV 文件
# -------------------------------------------
cd "$RESULT_DIR" || { echo "无法进入目录 $RESULT_DIR"; exit 1; }

# 提取日志文件中最后7行的内容（假设 *.log 存在）
Results=$(tail -n 7 *.log)

# 从包含 "==>" 的行中提取日志文件名（第二个字段）
LogFileName=$(echo "$Results" | grep '==>' | awk '{print $2}')

# 提取第一行和最后一行的文件名
first_line=$(echo "$LogFileName" | head -n 1)
last_line=$(echo "$LogFileName" | tail -n 1)

# 从文件名中提取日期及时间部分（第二和第三字段），去除尾部的 .log
first_date_time=$(echo "$first_line" | cut -d '-' -f2-3 | sed 's/\.log//')
last_date_time=$(echo "$last_line" | cut -d '-' -f2-3 | sed 's/\.log//')
first_date_time="${first_date_time:-/}"
last_date_time="${last_date_time:-/}"

# 构造日志结果文件名，放在 OUT_DIR 中
ResultsFile="${OUT_DIR}/results-${first_date_time}-to-${last_date_time}.log"

> "$ResultsFile"

for file in *.log; do
  [ -e "$file" ] || { echo "没有找到 .log 文件"; exit 0; }
  tail -n 7 "$file" > .tmp.log
  total=$(cat .tmp.log | grep "Total Tests:" | awk '{print $3}')
  skipped=$(cat .tmp.log | grep "Total Skipped Tests:" | awk '{print $4}')
  fail=$(cat .tmp.log | grep "Total Failures:" | awk '{print $3}')
  kernel=$(cat .tmp.log | grep "Kernel Version:" | awk '{print $3}')
  host=$(cat .tmp.log | grep "Hostname:" | awk '{print $2}')

  # 对空白项进行处理，若为空则替换为 "/"
  total="${total:-/}"
  skipped="${skipped:-/}"
  fail="${fail:-/}"
  kernel="${kernel:-/}"
  host="${host:-/}"

  echo "$SN,$file,$total,$skipped,$fail,$kernel,$host" >> "$ResultsFile"
  echo "已处理文件: $file -> $ResultsFile"
done

rm .tmp.log

# -------------------------------------------
# 5. 处理 .failed 文件，生成失败项 CSV 文件
# -------------------------------------------
cd "$FAILED_OUTPUT_DIR" || { echo "无法进入目录 $FAILED_OUTPUT_DIR"; exit 1; }

# 构造失败项输出文件名，放在 OUT_DIR 中
OutputFile="${OUT_DIR}/output-${first_date_time}-to-${last_date_time}.failed"

> "$OutputFile"

for file in *.failed; do
  [ -e "$file" ] || { echo "没有找到 .failed 文件"; exit 0; }

  if [ -s "$file" ]; then
    awk -v sn="$SN" -v fname="$file" '{print sn "," fname "," $0}' "$file"  >> "$OutputFile"
  else
    echo "$SN,$file,/" >> "$OutputFile"
  fi
  echo "已处理文件: $file -> $OutputFile"
done

echo "报告生成完毕，结果文件："
echo "  日志结果：$ResultsFile"
echo "  失败项：  $OutputFile"
