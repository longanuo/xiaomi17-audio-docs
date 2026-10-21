#!/system/bin/sh
MODDIR=${0%/*}
LOG=/data/adb/xiaomi17_stock_safe_audio.log
STAMP=/data/adb/xiaomi17_audio_mod_stage1
log() { echo "[$(date '+%F %T')] [post-fs-data v1.5.6] $*" >> "$LOG"; }
label_ok() { ls -Zd "$1" 2>/dev/null | grep -q 'u:object_r:vendor_configs_file:s0'; }
mount_one() {
  rel="$1"
  source="$MODDIR/system$rel"
  target="$rel"
  if [ ! -f "$source" ] || [ ! -e "$target" ]; then
    log "文件不存在：$rel"
    return 1
  fi
  # 挂载前校正源标签，避免管理器统一重置标签后 HAL 无法读取。
  if ! label_ok "$source"; then
    if ! chcon u:object_r:vendor_configs_file:s0 "$source" 2>>"$LOG" || ! label_ok "$source"; then
      log "配置标签设置失败：$rel"
      return 1
    fi
  fi
  if cmp -s "$source" "$target" && label_ok "$target"; then
    log "文件与读取标签已生效：$rel"
    return 0
  fi
  if mount --bind "$source" "$target" 2>>"$LOG" && cmp -s "$source" "$target" && label_ok "$target"; then
    log "bind mount 与读取标签生效：$rel"
    return 0
  fi
  log "文件覆盖或读取标签校验失败：$rel"
  return 1
}
ok=1
mount_one /odm/etc/audio/audio_effects_config.json || ok=0
mount_one /odm/etc/dolby/dax-default.xml || ok=0
mount_one /odm/etc/dolby/dax-default-spatializer.xml || ok=0
mount_one /odm/etc/audio_policy_engine_stream_volumes_mi.xml || ok=0
echo "version=1.5.6 ok=$ok" > "$STAMP"
chmod 0644 "$STAMP" 2>/dev/null
