# AI小说编辑器后端 - 多阶段构建 Dockerfile
FROM python:3.11-slim as base

# 设置工作目录
WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    default-libmysqlclient-dev \
    pkg-config \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 创建非root用户
RUN useradd --create-home --shell /bin/bash app \
    && chown -R app:app /app
USER app

# 设置Python环境
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

# 复制依赖文件
COPY --chown=app:app requirements.txt .

# 安装Python依赖
RUN pip install --user --no-cache-dir -r requirements.txt

# 开发阶段
FROM base as development

# 安装开发依赖
COPY --chown=app:app requirements-dev.txt* ./
RUN if [ -f requirements-dev.txt ]; then \
    pip install --user --no-cache-dir -r requirements-dev.txt; \
    fi

# 复制源代码
COPY --chown=app:app . .

# 创建数据和日志目录
RUN mkdir -p /app/data /app/logs

# 暴露端口
EXPOSE 8000

# 开发环境启动命令
CMD ["uvicorn", "main:app", "--reload", "--host", "0.0.0.0", "--port", "8000"]

# 生产阶段
FROM base as production

# 复制源代码
COPY --chown=app:app . .

# 创建必要目录
RUN mkdir -p /app/data /app/logs

# 设置生产环境变量
ENV DEBUG=false

# 健康检查
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# 暴露端口
EXPOSE 8000

# 生产环境启动命令
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
