#!/bin/bash
# ============================================================================
# Personal Wiki 自动化部署脚本
# 执行流程：插件校验 -> Quartz 构建 -> 产物验证 -> rsync 同步 -> Nginx 重载
# ============================================================================

# ================= 配置区（请替换为您的实际路径） =================
QUARTZ_DIR="/opt/<YOUR_USER>/wiki/quartz"
WEB_DIR="/var/www/<YOUR_USER>/html"
LOG_DIR="/opt/<YOUR_USER>/wiki/logs"
LOCK_FILE="/tmp/quartz_deploy.lock"
LOG_FILE="$LOG_DIR/deploy_$(date +%Y%m%d_%H%M%S).log"

# ================= 初始化 =================
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

# 防止并发构建
if [ -f "$LOCK_FILE" ]; then
    echo "$(date): [WARN] 另一个构建任务正在运行，跳过本次触发。"
    exit 0
fi
touch "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

echo "$(date): [INFO] 开始 Personal Wiki 自动化部署..."

# ================= [1/4] 校验 Quartz 插件 =================
cd "$QUARTZ_DIR" || { echo "$(date): [ERROR] 无法进入 Quartz 目录: $QUARTZ_DIR"; exit 1; }

echo "$(date): [1/4] 校验 Quartz 插件..."
PLUGIN_OUTPUT=$(npx quartz plugin restore 2>&1)
PLUGIN_EXIT=$?
echo "$PLUGIN_OUTPUT"

if [ $PLUGIN_EXIT -ne 0 ]; then
    echo "$(date): [ERROR] Quartz 插件恢复失败（退出码: $PLUGIN_EXIT）"
    exit 1
fi
echo "$(date): [OK] 插件校验通过"

# ================= [2/4] 构建 Quartz 站点 =================
echo "$(date): [2/4] 构建 Quartz 站点..."
BUILD_OUTPUT=$(npx quartz build 2>&1)
BUILD_EXIT=$?
echo "$BUILD_OUTPUT"

if [ $BUILD_EXIT -ne 0 ]; then
    echo "$(date): [ERROR] Quartz 构建失败（退出码: $BUILD_EXIT）"
    exit 1
fi

# 验证构建产物
if [ ! -f "public/index.html" ]; then
    echo "$(date): [ERROR] 构建验证失败：未生成 public/index.html"
    exit 1
fi
echo "$(date): [OK] 构建验证通过，index.html 已生成"

# ================= [3/4] 同步文件到 Nginx 目录 =================
echo "$(date): [3/4] 同步文件到 Nginx 目录..."
if ! sudo rsync -avz --delete public/ "$WEB_DIR/"; then
    echo "$(date): [ERROR] rsync 同步失败"
    exit 1
fi
echo "$(date): [OK] 文件同步完成"

# ================= [4/4] 重载 Nginx =================
echo "$(date): [4/4] 重载 Nginx..."
if ! sudo systemctl reload nginx; then
    echo "$(date): [ERROR] Nginx 重载失败"
    exit 1
fi
echo "$(date): [OK] Nginx 重载成功"

echo "$(date): [SUCCESS] 部署成功完成！"
echo "$(date): [INFO] 部署日志: $LOG_FILE"
