#!/bin/bash

# ================= 配置区 (请替换为您的实际路径) =================
OBSIDIAN_DIR="/Users/<YOUR_USER>/WorkBuddy/LLMObsidian/studyObsidian"
INBOX_DIR="$OBSIDIAN_DIR/00-Inbox"
LOG_FILE="$OBSIDIAN_DIR/logs/auto_clipper.log"
EC2_HOST="<YOUR_EC2_USER>@<YOUR_EC2_IP>"
MAX_RETRIES=2

mkdir -p "$OBSIDIAN_DIR/logs"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

process_file() {
    local file="$1"
    local filename=$(basename "$file")
    
    [[ "$filename" == .* || "$filename" != *.md ]] && return
    
    log " 检测到新剪藏文件: $filename"
    cd "$OBSIDIAN_DIR" || exit 1
    
    git add .
    git commit -m "Auto Clipper: $filename" > /dev/null 2>&1
    log " 正在推送到 EC2..."
    git push ec2 main > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        log " Git Push 失败"
        return
    fi
    
    log " 等待 30 秒后检查 EC2 部署状态..."
    sleep 30
    
    success=false
    for ((i=1; i<=MAX_RETRIES; i++)); do
        log " 第 $i 次检查部署状态..."
        result=$(ssh "$EC2_HOST" "ls -lt /opt/<YOUR_USER>/wiki/logs/deploy_*.log | head -1 | awk '{print \$NF}' | xargs tail -5" 2>/dev/null)
        
        if echo "$result" | grep -q " 部署成功完成！"; then
            log " 部署成功！"
            success=true
            break
        else
            log "️ 未检测到成功标识，等待 15 秒后重试..."
            sleep 15
        fi
    done
    
    if [ "$success" = true ]; then
        log " 清理本地剪藏文件: $filename"
        rm -f "$file"
        git add . && git commit -m "Auto Clipper: 清理 $filename" > /dev/null 2>&1
        git push ec2 main > /dev/null 2>&1
    else
        log " 收藏失败：文件已保留在 00-Inbox。"
    fi
}

log " 开始监听 00-Inbox 目录..."
fswatch -0 --event Created --event Updated "$INBOX_DIR" | while read -d '' event; do
    process_file "$event"
done
