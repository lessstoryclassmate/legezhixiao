# AI小说编辑器前端 - 多阶段构建 Dockerfile
FROM node:18-alpine as base

WORKDIR /app

# 设置npm镜像源
RUN npm config set registry https://registry.npmmirror.com \
    && npm config set timeout 300000

# 安装基本工具
RUN apk add --no-cache curl

# 检查并安装yarn（如果需要）
RUN yarn --version || npm install -g yarn

# 设置yarn镜像源
RUN yarn config set registry https://registry.npmmirror.com \
    && yarn config set network-timeout 300000

# 创建非root用户
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# 开发阶段
FROM base as development

# 复制package文件
COPY package*.json ./
COPY yarn.lock* ./

# 安装所有依赖（包括开发依赖）
RUN yarn install

# 复制源代码
COPY . .

# 更改所有权
RUN chown -R nextjs:nodejs /app
USER nextjs

# 暴露端口
EXPOSE 3000

# 开发环境启动命令
CMD ["yarn", "dev", "--host", "0.0.0.0", "--port", "3000"]

# 构建阶段
FROM base as builder

# 复制package文件
COPY package*.json ./
COPY yarn.lock* ./

# 安装依赖（只安装生产依赖）
RUN yarn install --frozen-lockfile --production=false

# 复制源代码
COPY . .

# 构建应用
RUN yarn build

# 生产阶段
FROM nginx:alpine as production

# 安装curl用于健康检查
RUN apk add --no-cache curl

# 创建nginx用户
RUN addgroup -g 101 -S nginx && \
    adduser -S nginx -u 101 -G nginx

# 复制构建文件
COPY --from=builder /app/dist /usr/share/nginx/html

# 复制nginx配置
COPY nginx.conf /etc/nginx/nginx.conf

# 创建日志目录
RUN mkdir -p /var/log/nginx && \
    chown -R nginx:nginx /var/log/nginx /var/cache/nginx /etc/nginx

# 健康检查
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:80 || exit 1

# 暴露端口
EXPOSE 80 443

# 使用非root用户
USER nginx

# 启动命令
CMD ["nginx", "-g", "daemon off;"]
