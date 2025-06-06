#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

check_service_context() {
    local SERVICE_DIR=$1
    local SERVICE_NAME=$2
    
    echo -e "\n${BLUE}=== 检查 $SERVICE_NAME 服务的构建上下文 ===${NC}"
    
    # 检查服务目录是否存在
    if [ ! -d "$SERVICE_DIR" ]; then
        echo -e "${RED}错误: $SERVICE_NAME 目录 ($SERVICE_DIR) 不存在${NC}"
        return 1
    fi
    
    # 切换到服务目录
    cd "$SERVICE_DIR" || {
        echo -e "${RED}错误: 无法进入 $SERVICE_DIR 目录${NC}"
        return 1
    }
    
    # 检查 Dockerfile
    if [ ! -f Dockerfile ]; then
        echo -e "${RED}错误: $SERVICE_NAME 目录下没有找到 Dockerfile${NC}"
        cd - > /dev/null
        return 1
    fi
    
    echo -e "${GREEN}正在分析 $SERVICE_NAME 的构建上下文...${NC}"
    
    # 使用 docker build 显示构建上下文信息
    CONTEXT_INFO=$(docker build . --no-cache --quiet 2>&1 | grep "sending build context")
    
    if [ -n "$CONTEXT_INFO" ]; then
        echo -e "${GREEN}构建上下文信息：${NC}"
        echo "$CONTEXT_INFO"
    else
        echo -e "${YELLOW}无法获取构建上下文信息${NC}"
    fi
    
    echo -e "\n${GREEN}文件列表（将被包含在构建中）：${NC}"
    echo "----------------------------------------"
    
    # 使用 find 列出所有文件，排除 .git 和其他通常被忽略的目录
    find . -type f \
        ! -path "*/\.*" \
        ! -path "*/node_modules/*" \
        ! -path "*/__pycache__/*" \
        -exec ls -lh {} \; | sed 's|^./||'
    
    echo -e "\n${YELLOW}潜在警告检查：${NC}"
    # 检查常见的不应包含的文件和目录
    for PATTERN in "node_modules/" ".git/" ".env" "*.log" "*.tar.gz" "*.zip" "__pycache__" "*.pyc" ".DS_Store" "venv/" "dist/" "build/"; do
        if find . -name "$PATTERN" 2>/dev/null | grep -q .; then
            echo -e "${RED}警告: 发现可能不应该包含的文件模式: $PATTERN${NC}"
        fi
    done
    
    # 返回原目录
    cd - > /dev/null
}

# 主程序
echo -e "${BLUE}开始检查 Docker 构建上下文${NC}"

# 检查 .dockerignore
if [ -f "docker-compose.yaml" ]; then
    echo -e "${GREEN}找到 docker-compose.yaml${NC}"
else
    echo -e "${RED}警告: 未找到 docker-compose.yaml${NC}"
fi

# 检查前端服务
check_service_context "front-end-new" "Frontend"

# 检查后端服务
check_service_context "SmartEduServer" "Backend"

echo -e "\n${BLUE}=== 构建上下文检查完成 ===${NC}"
