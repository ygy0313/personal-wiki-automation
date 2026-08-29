#!/bin/bash
# ============================================================================
# Mac 端 00-Inbox 目录监控脚本
# 使用 fswatch 监听新文件，自动执行 Git 提交、推送和部署验证
# ============================================================================

# ================= 配置区（请替换为您的实际路径） =================
OBSIDIAN_DIR="/Users/<YOUR_USER>/WorkBuddy/LLMObsidian/studyObsidian"
INBOX_DIR="$OBSIDIAN_DIR/00-Inbox"
LOG_FILE="$OBSIDIAN_DIR/logs/auto_clipper.log"
EC2_HOST="<YOUR_EC2_USER>@<YOUR_EC2_IP>"
MAX_RETRIES=2
CHECK_INTERVAL=15

# ================= 初始化 =================
mkdir -p "$OBSIDIAN_DIR/logs"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# ================= 处理单个文件 =================
process_file() {
    local file="$1"
    local filename
    filename=$(basename "$file")

    # 跳过隐藏文件和 non-.md 文件
    [[ "$filename" == .* ]] && return
    [[ "$filename" != *.md ]] && return

    log "[INFO] 检测到新剪藏文件: $filename"

    cd "$OBSIDIAN_DIR" || exit 1

    # Git 提交
    git add .
    git commit -m "Auto Clipper: $filename" > /dev/null 2>&1
    log "[INFO] Git 提交完成"

    # 推送到 EC2
    log "[INFO] 正在推送到 EC2..."
    git push ec2 main > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        log "[ERROR] Git Push 失败，文件保留在 00-Inbox"
        return
    fi

    log "[INFO] 推送成功，等待 30 秒后检查 EC2 部署状态..."
    sleep 30

    # 检查部署状态
    local success=false
    for ((i=1; i<=MAX_RETRIES; i++)); do
        log "[INFO] 第 $i 次检查部署状态..."
        result=$(ssh "$EC2_HOST" "ls -lt /opt/<YOUR_USER>/wiki/logs/deploy_*.log 2>/dev/null | head -1 | awk '{print \$NF}' | xargs tail -5" 2>/dev/null)

        if echo "$result" | grep -q "部署成功完成"; then
            log "[OK] 部署成功！"
            success=true
            break
        else
            log "[WARN] 未检测到成功标识，等待 ${CHECK_INTERVAL} 秒后重试..."
            sleep "$CHECK_INTERVAL"
        fi
    done

    if [ "$success" = true ]; then
        log "[INFO] 清理本地剪藏文件: $filename"
        rm -f "$file"
        cd "$OBSIDIAN_DIR" && git add . && git commit -m "Auto Clipper: 清理 $filename" > /dev/null 2>&1
        git push ec2 main > /dev/null 2>&1
    else
        log "[ERROR] 部署失败：文件已保留在 00-Inbox，请手动检查"
    fi
}

# ================= 主循环 =================
log "[INFO] 开始监听 00-Inbox 目录: $INBOX_DIR"
fswatch -0 --event Created --event Updated "$INBOX_DIR" | while read -d '' event; do
    process_file "$event"
done
