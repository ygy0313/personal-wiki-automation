# Personal Wiki Automation System

一个基于 Obsidian + Git + AWS EC2 + Quartz + Nginx 的全链路自动化个人知识库部署系统。

## 核心特性

- **一键剪藏**：通过 Obsidian Web Clipper 将网页内容一键保存至本地 `00-Inbox`。
- **自动推送**：Mac 端后台静默监控 `00-Inbox` 目录，检测到新文件自动执行 Git 提交与推送。
- **云端构建**：AWS EC2 接收 Push 后自动触发 Quartz 构建静态站点。
- **无缝部署**：自动同步至 Nginx 目录并重载服务，实现秒级上线。
- **全链路测试**：内置自动化测试脚本，验证从剪藏到网站更新的完整闭环。

## 系统架构图

```
[本地 Mac]                    [传输层]              [AWS EC2]
+------------------+          +----------+         +------------------+
| Obsidian         |          |          |         | post-receive     |
|  - Web Clipper   |----+     |          |         | Hook             |
|  - 00-Inbox/     |     |    | Git Push |-------->| - rsync content  |
|       v          |     |    |          |         | - deploy.sh      |
| auto_clipper.sh  |     |    |          |         |   + plugin restore|
|  (fswatch)       |----+     |          |         |   + quartz build  |
+------------------+          +----------+         |   + verify index  |
                                                   |   + rsync -> Nginx|
                                                   |   + reload nginx  |
                                                   |         v         |
                                                   | https://<DOMAIN>  |
                                                   +------------------+
```

## 目录结构

```
personal-wiki-automation/
+-- README.md                # 项目说明与架构图
+-- ARCHITECTURE.md          # 详细系统架构文档
+-- LICENSE                  # MIT 开源协议
+-- .gitignore               # Git 忽略文件配置
+-- scripts/
|   +-- deploy.sh            # EC2 端自动化部署脚本
|   +-- auto_clipper.sh      # Mac 端 Inbox 目录监控脚本
|   +-- start_clipper.sh     # Mac 端后台服务管理脚本
|   +-- test_full_pipeline.sh # 全链路自动化测试脚本
|   +-- debug_ec2.sh         # EC2 端一键诊断脚本
|   +-- debug_mac.sh         # Mac 端一键诊断脚本
+-- config/
    +-- nginx-trojan-go.conf # Nginx 配置模板
    +-- post-receive         # Git 裸仓库 post-receive 钩子模板
```

## 快速开始

请参考 `ARCHITECTURE.md` 获取详细的部署与配置指南。

## 部署前须知

部署前需将脚本和配置文件中的 `<YOUR_XXX>` 占位符替换为实际环境信息：

| 占位符 | 说明 |
|--------|------|
| `<YOUR_USER>` | EC2 用户名（如 ec2-user） |
| `<YOUR_DOMAIN>` | 您的域名（如 wiki.example.com） |
| `<YOUR_TROJAN_PATH>` | Trojan-go 代理路径 |
| `<YOUR_TROJAN_PORT>` | Trojan-go 监听端口 |
| `<YOUR_TROJAN_PROTOCOL>` | Trojan 协议类型 |
| `<YOUR_GITHUB_USERNAME>` | GitHub 用户名 |

## 常见问题

### README.md 中文乱码

如果 GitHub 上 README.md 的中文显示为乱码，请确保文件以 **UTF-8 无 BOM** 编码保存。在 macOS 终端中重新保存文件：

```bash
# 检查文件编码
file -I README.md

# 如果显示非 UTF-8，重新编码保存
iconv -f GBK -t UTF-8 README.md > README.md.new
mv README.md.new README.md

# 然后重新提交推送
git add README.md
git commit -m "Fix: re-encode README.md to UTF-8"
git push
```

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
