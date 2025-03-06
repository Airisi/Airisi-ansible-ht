## **测试步骤说明**  

### **一、测试准备**

#### **1. 拷贝测试脚本**  
- 创建远程目录 `/root/timelog`（若不存在）  
- 复制 `sntp-timedlogger.sh` `tick_freq-timedlogger` 测试脚本到目标机器  

```bash
ansible all -m shell -a 'mkdir -p /root/timelog'
ansible-playbook c61/copy_file_to_remote.yml
ansible-playbook s2210/copy_file_to_remote.yml
```

#### **2. 关闭对时相关服务**  
- 停止 NTP 对时服务，避免干扰测试  

```bash
ansible all -m shell -a 'systemctl stop ntp'
```

#### **3. 查询当前时间漂移状态**  
- 通过 `adjtimex -p` 检查当前时钟状态  

```bash
ansible all -m shell -a 'adjtimex -p'
```

#### **4. 网络及时间同步**  
- 添加默认网关  
- 手动设定时间或使用 `ntpdate` 进行对时

```bash
ansible all -m shell -a 'route add default gw 192.168.66.1'
ansible all -m shell -a 'ntpdate ntp.aliyun.com'
```

## **二、系统时钟漂移率测试**

### **1. 执行系统时钟漂移率记录脚本**
- 启动 `tick_freq-timedlogger.sh`，并让其在后台运行

```bash
ansible all -m shell -a 'chdir=/root/timelog/ nohup ./tick_freq-timedlogger.sh &'
```
#### **2. 查看进程状态**
- 确保 `ntp` 与 `tick_freq-timedlogger.sh` 进程已启动

```bash
ansible all -m shell -a 'ps -ef | grep -E "ntp|tick_freq-timedlogger"'
```
#### **3. 查看测试结果**
- 列出 `timelog` 目录中的文件
- 查看 `time1h`、`time10s` 相关日志文件内容

```bash
ansible all -m shell -a 'ls /root/timelog/'
ansible all -m shell -a 'cat /root/timelog/time1h.csv'
ansible all -m shell -a 'head /root/timelog/time10s.csv'
ansible all -m shell -a 'tail /root/timelog/time10s.csv'
```

#### **4. 终止测试**

```bash
ansible all -m shell -a 'killall tick_freq-timedlogger'
---

## **三、校正后系统时钟漂移测试**

#### **1. 执行漂移记录脚本**  
- 启动 `sntp-timedlogger.sh`，并让其在后台运行  

```bash
ansible all -m shell -a 'chdir=/root/timelog/ nohup ./sntp-timedlogger.sh &'
```

#### **2. 查看进程状态**  
- 确保 `ntp` 进程未启动，`sntp-timedlogger.sh` 已启动  

```bash
ansible all -m shell -a 'ps -ef | grep ntp'
```

#### **3. 查看测试结果**  
- 列出 `timelog` 目录中的文件  
- 查看 `time1h`、`time10s` 相关日志文件内容  

```bash
ansible all -m shell -a 'ls /root/timelog/'
ansible all -m shell -a 'cat /root/timelog/time1h_*'
ansible all -m shell -a 'head /root/timelog/time10s_*.csv'
ansible all -m shell -a 'tail /root/timelog/time10s_*.csv'
```

#### **4. 终止测试**

```bash
ansible all -m shell -a 'killall sntp-timedlogger.sh'
---

- 注意 两项测试不能同时进行
