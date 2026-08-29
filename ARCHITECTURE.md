# 系统架构详解

## 1. 本地 Mac 端 (数据采集与触发)
- **Obsidian Web Clipper**：浏览器插件，将网页一键保存为 Markdown 到 `00-Inbox/`。
- **auto_clipper.sh**：使用 `fswatch` 监控 `00-Inbox` 目录，捕获文件创建事件后自动执行 Git 提交与推送。
- **start_clipper.sh**：管理 `auto_clipper.sh` 的后台生命周期（Start/Stop/Status）。

## 2. 传输层
- **Git Push**：本地代码自动推送到 EC2 上的 Git 裸仓库。

## 3. AWS EC2 云端 (处理与发布)
- **post-receive Hook**：Git 服务端钩子，接收 Push 后异步触发 `deploy.sh`。
- **deploy.sh**：核心部署脚本，依次执行：
  1. 校验 Quartz 插件 (`npx quartz plugin restore`)
  2. 构建站点 (`npx quartz build`)
  3. 验证构建产物 (`public/index.html`)
  4. 同步文件至 Nginx 目录 (`rsync`)
  5. 重载 Nginx (`systemctl reload nginx`)
- **Nginx**：配置 HTTPS 及 `try_files $uri $uri.html $uri/ =404;` 规则，确保 Quartz 生成的无扩展名 URL 正确解析。

## 4. 调试与测试
- `test_full_pipeline.sh`：模拟剪藏并验证全链路。
- `debug_ec2.sh` / `debug_mac.sh`：一键排查常见故障。

## ️ 注意事项
部署前需将脚本和配置文件中的 `<YOUR_XXX>` 占位符替换为实际环境信息。