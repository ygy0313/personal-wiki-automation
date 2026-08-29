#!/bin/bash
# ============================================================================
# Mac 端 Auto Clipper 后台服务管理脚本
# 用法: ./start_clipper.sh {start|stop|status}
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$SCRIPT_DIR/../logs/auto_clipper.pid"
mkdir -p "$SCRIPT_DIR/../logs"

case "$1" in
  start)
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo "Auto Clipper 已经在运行 (PID: $(cat "$PID_FILE"))"
    else
        echo "启动 Auto Clipper 后台监控..."
        nohup "$SCRIPT_DIR/auto_clipper.sh" > /dev/null 2>&1 &
        echo $! > "$PID_FILE"
        echo "Auto Clipper 已启动 (PID: $!)"
    fi
    ;;
  stop)
    if [ -f "$PID_FILE" ]; then
        kill $(cat "$PID_FILE") 2>/dev/null
        rm -f "$PID_FILE"
        echo "Auto Clipper 已停止。"
    else
        echo "Auto Clipper 未在运行。"
    fi
    ;;
  status)
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo "Auto Clipper 正在运行 (PID: $(cat "$PID_FILE"))"
    else
        echo "Auto Clipper 未在运行。"
    fi
    ;;
  *)
    echo "用法: $0 {start|stop|status}"
    exit 1
    ;;
esac
