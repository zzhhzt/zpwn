# CTF Pwn Docker 镜像使用说明

## 镜像特性

这是一个专为CTF pwn方向设计的Docker镜像，包含完整的二进制漏洞利用工具链。

### 主要工具
- **Python工具**: pwntools, ropper, z3-solver, angr 等
- **Ruby工具**: one_gadget, seccomp-tools
- **调试器**: gdb-multiarch + pwndbg + Pwngdb
- **多版本glibc**: 2.19-2.36 (32/64位)
- **环境**: Zsh + Oh-My-Zsh, Python虚拟环境

## 构建镜像

### 使用默认密码构建
```bash
docker build -t ctf-pwn .
```

### 使用自定义密码构建
```bash
docker build \
  --build-arg ROOT_PASSWORD=your_root_password \
  --build-arg ZPWN_PASSWORD=your_zpwn_password \
  -t ctf-pwn .
```

## 运行容器

### 基本运行
```bash
docker run -d -p 2222:22 --name ctf-pwn-container ctf-pwn
```

### 挂载工作目录
```bash
docker run -d -p 2222:22 \
  -v /path/to/your/ctf/files:/ctf/work \
  --name ctf-pwn-container ctf-pwn
```

### 完整运行示例
```bash
# 创建工作目录
mkdir -p ~/ctf-workspace

# 运行容器并挂载工作目录
docker run -d -p 2222:22 \
  -v ~/ctf-workspace:/ctf/work \
  --name ctf-pwn ctf-pwn

# 连接到容器
ssh zpwn@localhost -p 2222
# 默认密码: zzh234234 (或你设置的密码)
```

## 容器内使用

### SSH连接
```bash
# 连接zpwn用户
ssh zpwn@localhost -p 2222

# 连接root用户
ssh root@localhost -p 2222
```

### 工具使用示例

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
| `ROOT_PASSWORD` | `zzh234234` | root用户密码 |
| `ZPWN_PASSWORD` | `zzh234234` | zpwn用户密码 |

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

如有问题或建议，请提交Issue或Pull Request。