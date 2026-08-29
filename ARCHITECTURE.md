# 系统架构详解

## 1. 本地 Mac 端（数据采集与触发）

### Obsidian Web Clipper
浏览器插件，将网页一键保存为 Markdown 文件到 `00-Inbox/` 目录。

### auto_clipper.sh
使用 `fswatch` 监控 `00-Inbox` 目录，捕获文件创建事件后自动执行：
1. `git add .` — 暂存所有变更
2. `git commit` — 提交并附带文件名为注释
3. `git push ec2 main` — 推送到 EC2 远程仓库
4. 等待 30 秒后检查部署状态
5. 成功则清理本地剪藏文件，失败则保留文件

### start_clipper.sh
管理 `auto_clipper.sh` 的后台生命周期：
- `start` — 后台启动监控
- `stop` — 停止监控进程
- `status` — 查看运行状态

## 2. 传输层

### Git Push
本地代码通过 SSH 自动推送到 EC2 上的 Git 裸仓库（remote name: `ec2`）。

## 3. AWS EC2 云端（处理与发布）

### post-receive Hook
Git 服务端钩子，在接收到 Push 后异步触发 `deploy.sh`：
1. 将 Git 工作树更新到 content 目录
2. rsync 同步内容到 Quartz 工作目录
3. 后台异步执行部署脚本

### deploy.sh
核心部署脚本，依次执行：
1. **插件校验**：`npx quartz plugin restore` 确保依赖完整
2. **构建站点**：`npx quartz build` 生成静态 HTML
3. **产物验证**：检查 `public/index.html` 是否存在
4. **同步部署**：`sudo rsync -avz --delete public/` 同步到 Nginx 目录
5. **重载服务**：`sudo systemctl reload nginx` 使新内容生效

### Nginx 配置要点
- HTTPS 强制跳转（HTTP -> HTTPS 301）
- `try_files $uri $uri.html $uri/ =404;` 支持 Quartz 无扩展名 URL
- SSL 证书由 Certbot 自动管理
- `/ssl112233` 路径代理到 Trojan-go（按需保留）

## 4. 调试与测试

### test_full_pipeline.sh
全链路自动化测试脚本：
1. 在本地模拟创建测试 Markdown 文件
2. 触发 Git 提交和推送
3. 等待部署完成
4. 验证 Nginx 可正常访问
5. 清理测试数据

### debug_ec2.sh
EC2 端一键诊断脚本，检查：
- Git 裸仓库状态
- post-receive 钩子权限
- Nginx 配置语法
- `try_files` 是否正确
- Quartz 构建产物
- 最近部署日志

### debug_mac.sh
Mac 端一键诊断脚本，检查：
- `fswatch` 是否安装
- Git 远程仓库配置
- `auto_clipper.sh` 监听进程
- 日志文件内容

## 5. 数据流

```
用户剪藏网页
    |
    v
Obsidian Web Clipper -> 00-Inbox/xxx.md
    |
    v
auto_clipper.sh (fswatch 检测到新文件)
    |
    v
git add -> git commit -> git push ec2 main
    |
    v
EC2: post-receive Hook 触发
    |
    v
rsync 同步 content -> Quartz 工作目录
    |
    v
deploy.sh: plugin restore -> quartz build -> rsync -> nginx reload
    |
    v
网站更新完成，用户可访问
```

## 6. 待开发模块

### Knowledge Engine（AI 自动化处理）
- 监控 `00-Inbox` 目录新文件
- 调用 LLM 提取正文、生成摘要、自动分类、打标签
- 将处理后的笔记移动到 `01-Knowledge` / `03-Concepts` 等目录
- 触发 Quartz 重新构建

### AWS OpenSearch 集成
- 将 Quartz 构建产物索引到 OpenSearch
- 支持全文搜索和知识图谱可视化
- 需解决同一文章重复收录问题（使用文件路径作为文档 `_id`）
