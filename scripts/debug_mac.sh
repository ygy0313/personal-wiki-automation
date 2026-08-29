#!/bin/bash
# ============================================================================
# Mac 端一键诊断脚本
# 检查 fswatch、Git 远程、监听进程、日志等关键组件
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }
info() { echo -e "${YELLOW}[INFO]${NC} $1"; }

echo "============================================"
echo " Mac 端诊断工具"
echo "============================================"
echo " 时间: $(date)"
echo ""

# 1. fswatch
info "1. 检查 fswatch..."
if command -v fswatch &> /dev/null; then
    pass "fswatch 已安装: $(which fswatch)"
else
    fail "fswatch 未安装，请执行: brew install fswatch"
fi

# 2. Git 远程
info "2. 检查 Git 远程仓库..."
OBSIDIAN_DIR="/Users/<YOUR_USER>/WorkBuddy/LLMObsidian/studyObsidian"
if [ -d "$OBSIDIAN_DIR/.git" ]; then
    pass "Git 仓库存在"
    if git -C "$OBSIDIAN_DIR" remote | grep -q "ec2"; then
        ec2_url=$(git -C "$OBSIDIAN_DIR" remote get-url ec2)
        pass "Git 远程 'ec2' 已配置: $ec2_url"
    else
        fail "Git 远程 'ec2' 未配置"
    fi
else
    fail "Obsidian 目录不是 Git 仓库: $OBSIDIAN_DIR"
fi

# 3. auto_clipper 进程
info "3. 检查 auto_clipper 进程..."
if pgrep -f "auto_clipper.sh" &> /dev/null; then
    pid=$(pgrep -f "auto_clipper.sh" | head -1)
    pass "auto_clipper.sh 正在运行 (PID: $pid)"
else
    info "auto_clipper.sh 未在运行"
fi

# 4. 日志文件
info "4. 检查日志文件..."
LOG_FILE="$OBSIDIAN_DIR/logs/auto_clipper.log"
if [ -f "$LOG_FILE" ]; then
    pass "日志文件存在: $LOG_FILE"
    echo "--- 最近 10 行 ---"
    tail -10 "$LOG_FILE"
else
    info "日志文件不存在（尚未产生日志）"
fi

# 5. 00-Inbox 目录
info "5. 检查 00-Inbox 目录..."
INBOX_DIR="$OBSIDIAN_DIR/00-Inbox"
if [ -d "$INBOX_DIR" ]; then
    file_count=$(find "$INBOX_DIR" -name "*.md" | wc -l)
    pass "00-Inbox 目录存在，共 $file_count 个 Markdown 文件"
    if [ "$file_count" -gt 0 ]; then
        echo "--- 未推送的文件 ---"
        find "$INBOX_DIR" -name "*.md" -type f -exec basename {} \;
    fi
else
    fail "00-Inbox 目录不存在: $INBOX_DIR"
fi

echo ""
echo "============================================"
echo " 诊断完成"
echo "============================================"
