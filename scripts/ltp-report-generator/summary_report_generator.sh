#!/bin/bash

#set -e
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

cd $SCRIPT_DIR

cd ../../

DATE_TIME=-$(date +'%Y_%m_%d-%Hh_%Mm_%Ss')
DATE_TIME=

OUT_DIR="output"
[ ! -d "$OUT_DIR" ] && mkdir -p "$OUT_DIR"

# 定义输出文件
Results_File="$OUT_DIR/log$DATE_TIME.csv"
Failed_File="$OUT_DIR/failed$DATE_TIME.csv"
Report_File="$OUT_DIR/report$DATE_TIME.xlsx"

host=$1
report="/opt/ltp-install/report"

ansible $host -m shell -a '/opt/ltp-install/singlehost_report_generator.sh'

ansible $host -m shell -a "cat $report/*.log" > .tmp.log

# 清空输出文件内容
> "$Results_File"

echo "IP/SN,Log File,Total Tests,Total Skipped Tests,Total Failures,Kernel Version,Hostname" > "$Results_File"

rc=1

# 逐行读取文件内容
while IFS= read -r line; do
    if  [[ "$line" =~ ^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)[[:space:]]+\|[[:space:]]+FAILED[[:space:]]+\|[[:space:]]+rc=[1-9][[:space:]]+\>\> ]]; then
        ip="${BASH_REMATCH[1]}"
	echo "$line"
	echo "$ip,FAILED,/,/,/,/,/" >> $Results_File
	rc=1
	continue
    fi

    # 判断是否为包含 "| CHANGED | rc=0 >>" 的 header 行，并提取 IP
    if [[ "$line" =~ ^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)[[:space:]]+\|[[:space:]]+CHANGED[[:space:]]+\|[[:space:]]+rc=0[[:space:]]+\>\> ]]; then
        ip="${BASH_REMATCH[1]}"
	rc=0
        # 读取 header 行后的下一行
        read -r next_line
            # 将提取的 IP 与下一行内容用空格连接后写入输出文件
            echo "$ip/$next_line" >> "$Results_File"
	continue
    fi

    if [[ "$rc" == 0 ]]; then
	echo "$ip/$line" >> "$Results_File"
    else
        echo "$line"
    fi
done < ".tmp.log"

ansible $host -m shell -a "cat $report/*.failed" > .tmp.log

> "$Failed_File"

echo "IP/SN,Log File,Failures" > "$Failed_File"

rc=1

# 逐行读取文件内容
while IFS= read -r line; do
    if  [[ "$line" =~ ^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)[[:space:]]+\|[[:space:]]+FAILED[[:space:]]+\|[[:space:]]+rc=1[[:space:]]+\>\> ]]; then
        ip="${BASH_REMATCH[1]}"
	echo "$line"
        echo "$ip,FAILED rc=1,/" >> $Failed_File
        rc=1
        continue
    fi

    # 判断是否为包含 "| CHANGED | rc=0 >>" 的 header 行，并提取 IP
    if [[ "$line" =~ ^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)[[:space:]]+\|[[:space:]]+CHANGED[[:space:]]+\|[[:space:]]+rc=0[[:space:]]+\>\> ]]; then
        ip="${BASH_REMATCH[1]}"
        rc=0
        # 读取 header 行后的下一行
        read -r next_line
            # 将提取的 IP 与下一行内容用空格连接后写入输出文件
            echo "$ip/$next_line" >> "$Failed_File"
        continue
    fi

    if [[ "$rc" == 0 ]]; then
        echo "$ip/$line" >> "$Failed_File"
    else
        echo "$line"
    fi
done < ".tmp.log"

rm .tmp.log

cd $SCRIPT_DIR

python3 report_generator.py --results "../../$Results_File" --failed "../../$Failed_File" --output "../../$Report_File"

