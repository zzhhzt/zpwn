# CTF Pwn Docker 镜像使用说明

## 镜像特性

这是一个专为CTF pwn方向设计的Docker镜像，包含完整的二进制漏洞利用工具链。

### 主要工具
- **Python工具**: pwntools, ropper, z3-solver, angr 等
- **Ruby工具**: one_gadget, seccomp-tools
- **调试器**: gdb-multiarch + pwndbg + Pwngdb
- **编辑器**: Vim (已配置中文编码支持)
- **终端复用**: tmux (已启用鼠标支持)
- **多版本glibc**: 2.19-2.36 (32/64位)
- **环境**: Zsh + Oh-My-Zsh, Python虚拟环境

## 快速部署

### 方法一：Docker Compose (推荐)

```bash
# 1. 配置环境变量
cp .env.example .env
# 编辑 .env 文件设置密码和端口

# 2. 启动服务
docker-compose up -d

# 3. 连接到容器
ssh zpwn@localhost -p 2222  # 密码在 .env 中设置
```

### 方法二：传统 Docker 命令

#### 构建镜像
```bash
# 使用默认密码构建
docker build -t ctf-pwn .

# 使用自定义密码构建
docker build \
  --build-arg ROOT_PASSWORD=your_root_password \
  --build-arg ZPWN_PASSWORD=your_zpwn_password \
  -t ctf-pwn .
```

#### 运行容器
```bash
# 基本运行
docker run -d -p 2222:22 --name ctf-pwn-container ctf-pwn

# 挂载工作目录
docker run -d -p 2222:22 \
  -v /path/to/your/ctf/files:/ctf/work \
  --name ctf-pwn-container ctf-pwn

# 完整示例
mkdir -p ~/ctf-workspace
docker run -d -p 2222:22 \
  -v ~/ctf-workspace:/ctf/work \
  --name ctf-pwn ctf-pwn
ssh zpwn@localhost -p 2222
# 默认密码: 123456
```

### Docker Compose 环境配置

#### 生产环境
```bash
# 启动生产环境
docker-compose up -d

# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

#### 开发环境
```bash
# 启动开发环境(不同端口)
docker-compose -f docker-compose.dev.yml up -d

# 连接开发环境
ssh zpwn@localhost -p 2223
```

## 容器内使用

### SSH连接
```bash
# 连接zpwn用户
ssh zpwn@localhost -p 2222
# 默认密码: 123456

# 连接root用户
ssh root@localhost -p 2222
# 默认密码: 123456
```

### 工具使用示例

#### Vim编辑器 (已配置中文编码支持)
```bash
# Vim已预配置支持中文文件
vim 中文文件.txt

# 支持的编码格式：
# - UTF-8 (默认)
# - GBK/GB2312
# - GB18030
# - Big5

# Vim配置特性：
# - 自动检测文件编码
# - 语法高亮
# - 行号显示
# - 智能缩进
# - 搜索高亮
# - 中文字符正确显示
```

#### tmux终端复用器 (已启用鼠标支持)
```bash
# 启动tmux会话
tmux

# 鼠标操作功能:
# - 点击切换面板
# - 滚动查看历史输出
# - 拖拽选择文本复制
# - 调整面板大小

# 常用快捷键:
# Ctrl+b c      # 创建新窗口
# Ctrl+b "      # 水平分割面板
# Ctrl+b %      # 垂直分割面板
# Ctrl+b 方向键  # 切换面板
```

#### pwntools使用
```python
#!/usr/bin/env python3
from pwn import *

# 连接目标
p = remote('target.com', 12345)
p.sendline(b'exploit_payload')
p.interactive()
```

#### GDB调试
```bash
# 启动gdb (已配置pwndbg)
gdb ./binary

# 或使用gdb-multiarch
gdb-multiarch ./binary
```

#### one_gadget使用
```bash
# 查找one_gadget
one_gadget /lib/x86_64-linux-gnu/libc.so.6
```

### 工作目录
- 主要工作目录: `/ctf/work`
- glibc版本目录: `/glibc`
- 工具安装目录: `/opt/`

### Python环境
Python虚拟环境已自动激活，所有Python工具都已安装在其中。

## 环境变量说明

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `ROOT_PASSWORD` | `123456` | root用户密码 |
| `ZPWN_PASSWORD` | `123456` | zpwn用户密码 |

## 安全注意事项

1. **仅用于开发**: 本镜像适合CTF学习和开发，不建议在生产环境使用
2. **默认密码**: 构建时请务必修改默认密码
3. **网络隔离**: 建议在隔离的网络环境中使用
4. **权限管理**: 容器内用户拥有sudo权限，请谨慎操作

## 故障排除

### 常见问题

#### SSH连接失败
```bash
# 检查容器状态
docker ps | grep ctf-pwn

# 查看容器日志
docker logs ctf-pwn-container

# 重启SSH服务
docker exec ctf-pwn-container service ssh restart
```

#### 工具无法使用
```bash
# 进入容器检查
docker exec -it ctf-pwn-container bash

# 激活Python虚拟环境
source /pip_venv/bin/activate

# 测试工具
python3 -c "import pwntools; print('pwntools OK')"
```

### 性能优化

#### 增加内存限制
```bash
docker run -d -p 2222:22 \
  --memory=4g --memory-swap=4g \
  --name ctf-pwn ctf-pwn
```

#### 使用本地SSD
```bash
docker run -d -p 2222:22 \
  --tmpfs /tmp:exec \
  --name ctf-pwn ctf-pwn
```

## 构建优化说明

本Dockerfile已进行以下优化：

1. **环境变量密码**: 使用ARG参数，支持构建时自定义密码
2. **层优化**: 合并多个RUN指令，减少镜像层数
3. **缓存清理**: 自动清理apt、pip、gem缓存
4. **包管理优化**: 使用`--no-install-recommends`减少镜像大小

## 版本信息

- Ubuntu: 24.04
- Python: 3.x (系统版本)
- pwntools: 最新版
- GDB: 最新版 + pwndbg + Pwngdb

## 支持与反馈

## 文档链接

- 📖 [Docker Compose 使用指南](Docker-Compose-使用指南.md) - 详细的Docker Compose配置和使用说明
- 📋 [CTF Pwn Docker 分析报告](CTF_Pwn_Docker_Analysis.md) - 安全分析和优化建议
- 📝 [优化总结](优化总结.md) - 构建优化效果总结
- 📝 [RUN指令优化总结](RUN指令优化总结.md) - Dockerfile深度优化技术总结
- 🔤 [Vim中文配置说明](Vim中文配置说明.md) - Vim中文编码配置和使用指南

如有问题或建议，请提交Issue或Pull Request。