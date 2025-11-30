# Docker Compose 使用指南

## 概述

本项目提供了完整的Docker Compose配置，支持生产环境和开发环境的快速部署。

## 配置文件说明

### 1. docker-compose.yml (生产环境)
- 主要的Docker Compose配置文件
- 适用于CTF竞赛和常规使用
- 包含基本的端口映射和目录挂载

### 2. docker-compose.dev.yml (开发环境)
- 开发环境专用配置
- 挂载更多开发目录
- 使用不同的端口避免冲突
- 调试友好的配置

### 3. .env (环境变量配置)
- 密码和端口配置
- 资源限制设置
- 时区等环境配置

## 快速开始

### 1. 配置环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑配置文件
nano .env
```

### 2. 启动生产环境

```bash
# 构建并启动
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 3. 启动开发环境

```bash
# 构建并启动开发环境
docker-compose -f docker-compose.dev.yml up -d

# 查看开发环境状态
docker-compose -f docker-compose.dev.yml ps
```

## 环境变量详解

### .env 配置选项

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `ROOT_PASSWORD` | `123456` | root用户密码 |
| `ZPWN_PASSWORD` | `123456` | zpwn用户密码 |
| `SSH_PORT` | `2222` | SSH端口映射 |
| `TZ` | `Asia/Shanghai` | 时区设置 |
| `MEMORY_LIMIT` | `4G` | 内存限制(可选) |
| `CPU_LIMIT` | `2` | CPU限制(可选) |

## 目录挂载说明

### 生产环境挂载
```yaml
volumes:
  - ./workspace:/ctf/work          # 工作目录
```

### 开发环境挂载
```yaml
volumes:
  - ./workspace:/ctf/work          # 工作目录
  - ./scripts:/ctf/scripts         # 自定义脚本
  - ./challenges:/ctf/challenges   # CTF题目
  - ./configs:/ctf/configs         # 配置文件
```

## 常用命令

### 基本操作

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 重新构建并启动
docker-compose up -d --build

# 进入容器
docker-compose exec ctf-pwn bash

# 进入容器root用户
docker-compose exec -u root ctf-pwn bash
```

### 日志管理

```bash
# 查看所有日志
docker-compose logs

# 查看特定服务日志
docker-compose logs ctf-pwn

# 实时跟踪日志
docker-compose logs -f

# 查看最近100行日志
docker-compose logs --tail=100
```

### 网络管理

```bash
# 查看网络
docker network ls | grep ctf

# 查看网络详情
docker network inspect zpwn_ctf-network

# 测试连接
docker-compose exec ctf-pwn ping google.com
```

## 多环境管理

### 同时运行多个环境

```bash
# 启动生产环境
docker-compose up -d

# 启动开发环境(不同端口)
docker-compose -f docker-compose.dev.yml -p ctf-dev up -d
```

### 环境隔离

- **生产环境**: 网段 `172.20.0.0/16`，端口 `2222`
- **开发环境**: 网段 `172.21.0.0/16`，端口 `2223`

## 资源管理

### 启用资源限制

取消注释 `docker-compose.yml` 中的资源限制部分：

```yaml
deploy:
  resources:
    limits:
      memory: 4G
      cpus: '2'
    reservations:
      memory: 2G
      cpus: '1'
```

### 查看资源使用

```bash
# 查看容器资源使用
docker stats

# 查看磁盘使用
docker system df

# 清理未使用的资源
docker system prune
```

## 连接方式

### SSH连接

```bash
# 连接生产环境
ssh zpwn@localhost -p 2222

# 连接开发环境
ssh zpwn@localhost -p 2223

# 使用root连接
ssh root@localhost -p 2222
```

### 本地文件访问

```bash
# 查看工作目录
ls -la ./workspace/

# 向工作目录复制文件
cp exploit.py ./workspace/

# 从工作目录获取文件
cp ./workspace/output.txt ./
```

## 备份和恢复

### 数据备份

```bash
# 备份工作目录
tar -czf backup-$(date +%Y%m%d).tar.gz ./workspace

# 备份容器配置
docker-compose config > compose-backup.yml
```

### 环境迁移

```bash
# 导出镜像
docker save ctf-pwn:latest | gzip > ctf-pwn.tar.gz

# 在新环境导入
docker load < ctf-pwn.tar.gz

# 复制配置文件
scp docker-compose.yml .env user@new-host:/path/to/project/
```

## 故障排除

### 常见问题

1. **端口冲突**
   ```bash
   # 修改 .env 文件中的 SSH_PORT
   SSH_PORT=2223
   ```

2. **权限问题**
   ```bash
   # 修复目录权限
   sudo chown -R $USER:$USER ./workspace
   chmod -R 755 ./workspace
   ```

3. **网络问题**
   ```bash
   # 重建网络
   docker-compose down
   docker network prune
   docker-compose up -d
   ```

4. **镜像问题**
   ```bash
   # 重新构建镜像
   docker-compose down
   docker-compose build --no-cache
   docker-compose up -d
   ```

### 调试技巧

```bash
# 查看详细启动过程
docker-compose up

# 检查配置
docker-compose config

# 进入调试模式
docker-compose run --rm ctf-pwn bash

# 查看容器内部网络
docker-compose exec ctf-pwn ip addr
```

## 高级配置

### 自定义网络

```yaml
networks:
  custom-network:
    driver: bridge
    ipam:
      config:
        - subnet: 192.168.100.0/24
          gateway: 192.168.100.1
```

### 数据持久化

```yaml
volumes:
  ctf-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /path/to/host/directory
```

### 服务发现

```yaml
# 添加额外服务
services:
  database:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
    networks:
      - ctf-network
```

## 安全建议

1. **密码管理**: 使用强密码，避免默认密码
2. **网络安全**: 考虑使用防火墙限制SSH访问
3. **定期更新**: 定期更新基础镜像和依赖
4. **监控日志**: 定期检查容器日志
5. **备份重要**: 定期备份重要的配置和数据

## 性能优化

1. **使用SSD**: 将工作目录放在SSD上
2. **内存配置**: 根据需要调整内存限制
3. **并发限制**: 合理设置CPU限制
4. **镜像优化**: 使用多阶段构建减小镜像大小
5. **缓存利用**: 合理利用Docker层缓存