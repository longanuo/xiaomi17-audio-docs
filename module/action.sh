#!/system/bin/sh
# 模块页面“操作”按钮入口：生成生效自检报告
MODDIR=${0%/*}
exec "$MODDIR/selfcheck.sh"
