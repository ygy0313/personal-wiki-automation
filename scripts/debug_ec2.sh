#!/bin/bash
# ============================================================================
# EC2 端一键诊断脚本
# 检查 Git Hook、Nginx 配置、构建产物、日志等关键组件
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }
info() { echo -e "${YELLOW}[INFO]${NC} $1"; }

echo "============================================"
echo " EC2 环境诊断工具"
echo "============================================"
echo " 时间: $(date)"
echo " 主机: $(hostname)"
echo ""

# 1. Git 裸仓库
info "1. 检查 Git 裸仓库..."
GIT_DIR="/opt/<YOUR_USER>/wiki/repo/wiki.git"
if [ -d "$GIT_DIR" ]; then
    pass "Git 裸仓库存在: $GIT_DIR"
    if [ -f "$GIT_DIR/hooks/post-receive" ]; then
        pass "post-receive 钩子存在"
        if [ -x "$GIT_DIR/hooks/post-receive" ]; then
            pass "post-receive 钩子可执行"
        else
            fail "post-receive 钩子不可执行，请执行: chmod +x $GIT_DIR/hooks/post-receive"
        fi
    else
        fail "post-receive 钩子不存在"
    fi
else
    fail "Git 裸仓库不存在: $GIT_DIR"
fi

# 2. Nginx 配置
info "2. 检查 Nginx 配置..."
if command -v nginx &> /dev/null; then
    pass "Nginx 已安装"
    if nginx -t 2>&1 | grep -q "successful"; then
        pass "Nginx 配置语法正确"
    else
        fail "Nginx 配置语法错误"
        nginx -t 2>&1
    fi
    # 检查 try_files
    if grep -q 'try_files.*\$uri.html' /etc/nginx/conf.d/*.conf 2>/dev/null; then
        pass "try_files 包含 \$uri.html（Quartz 支持）"
    else
        fail "try_files 未包含 \$uri.html，Quartz 页面将 404"
    fi
else
    fail "Nginx 未安装"
fi

# 3. Quartz 构建产物
info "3. 检查 Quartz 构建产物..."
QUARTZ_DIR="/opt/<YOUR_USER>/wiki/quartz"
if [ -d "$QUARTZ_DIR" ]; then
    pass "Quartz 目录存在"
    if [ -d "$QUARTZ_DIR/public" ]; then
        file_count=$(find "$QUARTZ_DIR/public" -name "*.html" | wc -l)
        pass "Quartz public 目录存在，共 $file_count 个 HTML 文件"
    else
        fail "Quartz public 目录不存在，请执行: npx quartz build"
    fi
else
    fail "Quartz 目录不存在: $QUARTZ_DIR"
fi

# 4. Nginx 网站目录
info "4. 检查 Nginx 网站目录..."
WEB_DIR="/var/www/<YOUR_USER>/html"
if [ -d "$WEB_DIR" ]; then
    pass "Nginx 网站目录存在: $WEB_DIR"
    if [ -f "$WEB_DIR/index.html" ]; then
        pass "index.html 存在"
    else
        fail "index.html 不存在"
    fi
else
    fail "Nginx 网站目录不存在: $WEB_DIR"
fi

# 5. 部署日志
info "5. 检查最近部署日志..."
LOG_DIR="/opt/<YOUR_USER>/wiki/logs"
if [ -d "$LOG_DIR" ]; then
    latest_log=$(ls -lt "$LOG_DIR"/deploy_*.log 2>/dev/null | head -1 | awk '{print $NF}')
    if [ -n "$latest_log" ]; then
        pass "最近部署日志: $latest_log"
        echo "--- 最后 10 行 ---"
        tail -10 "$latest_log"
    else
        info "暂无部署日志"
    fi
else
    info "日志目录不存在"
fi

# 6. Nginx 服务状态
info "6. 检查 Nginx 服务状态..."
if systemctl is-active nginx &> /dev/null; then
    pass "Nginx 服务正在运行"
else
    fail "Nginx 服务未运行"
fi

echo ""
echo "============================================"
echo " 诊断完成"
echo "============================================"
