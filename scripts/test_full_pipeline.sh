#!/bin/bash
# ============================================================================
# 全链路自动化测试脚本
# 模拟剪藏 -> 推送 -> 验证 -> 清理 的完整闭环
# ============================================================================

# ================= 配置区 =================
OBSIDIAN_DIR="/Users/<YOUR_USER>/WorkBuddy/LLMObsidian/studyObsidian"
INBOX_DIR="$OBSIDIAN_DIR/00-Inbox"
EC2_HOST="<YOUR_EC2_USER>@<YOUR_EC2_IP>"
TEST_FILE="$INBOX_DIR/test-$(date +%Y%m%d_%H%M%S).md"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }
info() { echo -e "${YELLOW}[INFO]${NC} $1"; }

echo "============================================"
echo " Personal Wiki 全链路测试"
echo "============================================"

# 检查 fswatch
info "检查 fswatch 是否安装..."
if command -v fswatch &> /dev/null; then
    pass "fswatch 已安装"
else
    fail "fswatch 未安装，请执行: brew install fswatch"
    exit 1
fi

# 检查 Git 远程
info "检查 Git 远程仓库配置..."
cd "$OBSIDIAN_DIR" || { fail "无法进入 Obsidian 目录"; exit 1; }
if git remote | grep -q "ec2"; then
    pass "Git 远程 'ec2' 已配置"
else
    fail "Git 远程 'ec2' 未配置，请执行: git remote add ec2 <EC2_SSH_URL>"
    exit 1
fi

# 创建测试文件
info "创建测试文件: $(basename "$TEST_FILE")"
cat > "$TEST_FILE" << 'EOF'
# Test Page
This is an automated test page.
Date: $(date)
EOF

# 等待 fswatch 处理
info "等待 auto_clipper.sh 处理文件（最长 60 秒）..."
for i in $(seq 1 12); do
    sleep 5
    if [ ! -f "$TEST_FILE" ]; then
        pass "文件已被自动清理（推送成功）"
        break
    fi
    if [ "$i" -eq 12 ]; then
        fail "超时：文件未被自动清理"
    fi
done

# 检查 EC2 部署
info "检查 EC2 部署状态..."
result=$(ssh "$EC2_HOST" "ls -lt /opt/<YOUR_USER>/wiki/logs/deploy_*.log 2>/dev/null | head -1" 2>/dev/null)
if [ -n "$result" ]; then
    pass "EC2 部署日志存在"
    latest_log=$(echo "$result" | awk '{print $NF}')
    if ssh "$EC2_HOST" "tail -5 $latest_log 2>/dev/null" | grep -q "部署成功完成"; then
        pass "部署成功"
    else
        fail "未检测到部署成功标识"
    fi
else
    fail "EC2 部署日志不存在"
fi

# 检查 Nginx 可访问
info "检查 Nginx 可访问性..."
http_code=$(curl -s -o /dev/null -w "%{http_code}" "https://<YOUR_DOMAIN>/test-$(date +%Y%m%d_%H%M%S)" 2>/dev/null)
if [ "$http_code" = "200" ]; then
    pass "Nginx 返回 200，页面可访问"
else
    fail "Nginx 返回 $http_code，页面不可访问"
fi

# 清理测试文件
info "清理测试文件..."
rm -f "$TEST_FILE"
cd "$OBSIDIAN_DIR" && git add . && git commit -m "Test: cleanup test files" > /dev/null 2>&1
git push ec2 main > /dev/null 2>&1

echo ""
echo "============================================"
echo " 测试完成"
echo "============================================"
