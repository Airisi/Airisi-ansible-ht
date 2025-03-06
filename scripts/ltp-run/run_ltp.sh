#!/bin/bash

total_loops=$1

# 检查输入是否有效
if [[ -z "$total_loops" || ! "$total_loops" =~ ^[0-9]+$ || "$total_loops" -le 0 ]]; then
  echo "错误：请输入有效的正整数作为循环次数。"
  exit 1
fi

screen -dmS ltp bash -c '
{
  count=0
  while [ $count -lt '"$total_loops"' ]; do
    echo "[Loop $((count+1))] Test start"

    ./runltp -g LTP_RUN_ON-$(date +'%Y_%m_%d-%Hh_%Mm_%Ss').html &
    pid=$!
    wait $pid

    ((count++))
    echo "[Loop $count] Test end (PID: $pid)"
    sleep 300
    echo "Waiting for 5 minutes before restarting..."
  done
} '
