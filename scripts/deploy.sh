#!/bin/bash

# ================= 配置区 (请替换为您的实际路径) =================
QUARTZ_DIR="/opt/<YOUR_USER>/wiki/quartz"
WEB_DIR="/var/www/<YOUR_USER>/html"
LOG_DIR="/opt/<YOUR_USER>/wiki/logs"
LOCK_FILE="/tmp/quartz_deploy.lock"
LOG_FILE="$LOG_DIR/deploy_$(date +%Y%m%d_%H%M%S).log"

# ================= 初始化 =================
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

if [ -f "$LOCK_FILE" ]; then
    echo "$(date): ️ 另一个构建任务正在运行，跳过本次触发。"
    exit 0
fi
touch "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

echo "$(date):  开始 Personal Wiki 自动化部署..."

cd "$QUARTZ_DIR" || { echo "$(date):  无法进入 Quartz 目录"; exit 1; }

echo "$(date): [1/4] 校验 Quartz 插件..."
PLUGIN_OUTPUT=$(npx quartz plugin restore 2>&1)
echo "$PLUGIN_OUTPUT"

echo "$(date): [2/4] 构建 Quartz 站点..."
BUILD_OUTPUT=$(npx quartz build 2>&1)
BUILD_EXIT=$?
echo "$BUILD_OUTPUT"

if [ $BUILD_EXIT -ne 0 ]; then
    echo "$(date):  Quartz 构建失败（退出码: $BUILD_EXIT）"
    exit 1
fi

if [ ! -f "public/index.html" ]; then
    echo "$(date):  构建验证失败：未生成 public/index.html"
    exit 1
fi
echo "$(date):  构建验证通过"

echo "$(date): [3/4] 同步文件到 Nginx 目录..."
if ! sudo rsync -avz --delete public/ "$WEB_DIR/"; then
    echo "$(date):  rsync 同步失败"
    exit 1
fi

echo "$(date): [4/4] 重载 Nginx..."
if ! sudo systemctl reload nginx; then
    echo "$(date):  Nginx 重载失败"
    exit 1
fi

echo "$(date):  部署成功完成！"
