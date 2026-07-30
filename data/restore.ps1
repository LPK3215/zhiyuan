# 智愿系统数据恢复脚本
# 用法：在新环境中启动 Docker 服务后，运行此脚本导入数据
# PowerShell:  .\data\restore.ps1
# 说明：此脚本会清空 yuxi 数据库后重新导入，请确保 Docker 服务已启动

param([switch]$Force)

$ErrorActionPreference = "Stop"

$sqlFile = Join-Path $PSScriptRoot "yuxi_full.sql"

if (-not (Test-Path $sqlFile)) {
    Write-Host "错误：找不到数据文件 $sqlFile" -ForegroundColor Red
    exit 1
}

# 检查 postgres 容器是否运行
$running = docker ps --filter "name=postgres" --format "{{.Names}}" 2>$null
if ($running -ne "postgres") {
    Write-Host "错误：postgres 容器未运行，请先启动 Docker 服务" -ForegroundColor Red
    exit 1
}

if (-not $Force) {
    Write-Host "警告：此操作将清空并重新导入 yuxi 数据库的所有数据！" -ForegroundColor Yellow
    $confirm = Read-Host "确认继续？(y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "已取消" -ForegroundColor Gray
        exit 0
    }
}

Write-Host "`n[1/3] 清空现有数据..." -ForegroundColor Cyan
docker exec postgres psql -U postgres -d yuxi -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO postgres; GRANT ALL ON SCHEMA public TO public;" | Out-Null

Write-Host "[2/3] 导入数据..." -ForegroundColor Cyan
# 用 docker cp 把 SQL 文件传入容器，再执行，避免 PowerShell 编码问题
$tempPath = "/tmp/restore_yuxi.sql"
docker cp $sqlFile "postgres:$tempPath"
docker exec postgres psql -U postgres -d yuxi -f $tempPath | Out-Null
docker exec postgres rm $tempPath | Out-Null

Write-Host "[3/3] 验证数据..." -ForegroundColor Cyan
$unis = docker exec postgres psql -U postgres -d yuxi -t -c "SELECT COUNT(*) FROM zhiyuan_universities;"
$majors = docker exec postgres psql -U postgres -d yuxi -t -c "SELECT COUNT(*) FROM zhiyuan_majors;"
$scores = docker exec postgres psql -U postgres -d yuxi -t -c "SELECT COUNT(*) FROM zhiyuan_admission_scores;"
$users = docker exec postgres psql -U postgres -d yuxi -t -c "SELECT COUNT(*) FROM users;"

Write-Host "`n数据恢复完成！" -ForegroundColor Green
Write-Host "  院校数:   $unis" -ForegroundColor White
Write-Host "  专业数:   $majors" -ForegroundColor White
Write-Host "  分数数:   $scores" -ForegroundColor White
Write-Host "  用户数:   $users" -ForegroundColor White
