#!/bin/bash

check_directory() {
    local DIR=$1
    local SERVICE_DIR=$2
    
    echo "检查 $SERVICE_DIR 中的 $DIR 目录..."
    
    cd $SERVICE_DIR 2>/dev/null || {
        echo "错误: 无法进入 $SERVICE_DIR 目录"
        return 1
    }
    
    # 获取构建上下文大小和文件列表
    local CONTEXT_INFO=$(docker build . --no-cache --quiet 2>&1 | grep "sending build context")
    
    if [ -d "$DIR" ]; then
        echo "目录 $DIR 存在"
        # 检查该目录是否出现在构建上下文中
        local DIR_IN_CONTEXT=$(find . -type f -path "*/$DIR/*" -exec ls {} \; 2>/dev/null)
        
        if [ -n "$DIR_IN_CONTEXT" ]; then
            echo "警告: $DIR 目录被包含在构建上下文中!"
            echo "构建上下文信息: $CONTEXT_INFO"
            echo "第一个被包含的文件示例:"
            echo "$DIR_IN_CONTEXT" | head -n 1
        else
            echo "√ $DIR 目录已被成功排除"
        fi
    else
        echo "注意: $DIR 目录不存在"
    fi
    
    cd - > /dev/null
}

# 检查前端的 node_modules
check_directory "node_modules" "front-end-new"

# 检查后端的 venv
check_directory "venv" "SmartEduServer"