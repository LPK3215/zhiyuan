#!/bin/bash
# 智愿系统数据恢复脚本（Linux/macOS 版本）
# 用法：bash data/restore.sh
# 说明：此脚本会清空 yuxi 数据库后重新导入，请确保 Docker 服务已启动

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_FILE="$SCRIPT_DIR/yuxi_full.sql"

if [ ! -f "$SQL_FILE" ]; then
    echo "错误：找不到数据文件 $SQL_FILE"
    exit 1
fi

# 检查 postgres 容器是否运行
RUNNING=$(docker ps --filter "name=postgres" --format "{{.Names}}" 2>/dev/null)
if [ "$RUNNING" != "postgres" ]; then
    echo "错误：postgres 容器未运行，请先启动 Docker 服务"
    exit 1
fi

if [ "$1" != "-y" ]; then
    echo "警告：此操作将清空并重新导入 yuxi 数据库的所有数据！"
    read -p "确认继续？(y/N) " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "已取消"
        exit 0
    fi
fi

echo ""
echo "[1/3] 清空现有数据..."
docker exec postgres psql -U postgres -d yuxi -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO postgres; GRANT ALL ON SCHEMA public TO public;" > /dev/null

echo "[2/3] 导入数据..."
TEMP_PATH="/tmp/restore_yuxi.sql"
docker cp "$SQL_FILE" "postgres:$TEMP_PATH"
docker exec postgres psql -U postgres -d yuxi -f "$TEMP_PATH" > /dev/null
docker exec postgres rm "$TEMP_PATH" > /dev/null

echo "[3/3] 验证数据..."
UNIS=$(docker exec postgres psql -U postgres -d yuxi -t -c "SELECT COUNT(*) FROM zhiyuan_universities;")
MAJORS=$(docker exec postgres psql -U postgres -d yuxi -t -c "SELECT COUNT(*) FROM zhiyuan_majors;")
SCORES=$(docker exec postgres psql -U postgres -d yuxi -t -c "SELECT COUNT(*) FROM zhiyuan_admission_scores;")
USERS=$(docker exec postgres psql -U postgres -d yuxi -t -c "SELECT COUNT(*) FROM users;")

echo ""
echo "数据恢复完成！"
echo "  院校数:   $UNIS"
echo "  专业数:   $MAJORS"
echo "  分数数:   $SCORES"
echo "  用户数:   $USERS"
