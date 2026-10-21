#!/system/bin/sh
# Android 完成开机后，由 KernelSU / SukiSU Ultra 以 root 运行。

MODDIR=${0%/*}
CONFIG="$MODDIR/audio_tuning.conf"
LOG_FILE="/data/adb/xiaomi17_stock_safe_audio.log"
DOLBY_STATE_FILE="/data/adb/xiaomi17_stock_safe_audio_dolby_original"
MISOUND_STATE_FILE="/data/adb/xiaomi17_stock_safe_audio_misound_music_original"
SPATIAL_PROP_STATE_FILE="/data/adb/xiaomi17_stock_safe_audio_3dsurround_original"
SPATIAL_SETTING_STATE_FILE="/data/adb/xiaomi17_stock_safe_audio_spatial_setting_original"
ODM_SRC="$MODDIR/system/odm/etc/audio/audio_effects_config.json"
ODM_DST="/odm/etc/audio/audio_effects_config.json"
DEVICE="$(getprop ro.product.device)"

log() {
  echo "[$(date '+%F %T')] $*" >> "$LOG_FILE"
}

save_and_set_property() {
  property="$1"
  value="$2"
  state_file="$3"
  if [ ! -f "$state_file" ]; then
    getprop "$property" > "$state_file"
    chmod 0600 "$state_file"
  fi
  setprop "$property" "$value"
  log "已设置属性：$property=$value"
}

restore_property() {
  property="$1"
  state_file="$2"
  if [ -f "$state_file" ]; then
    setprop "$property" "$(cat "$state_file")"
    rm -f "$state_file"
    log "已恢复属性：$property"
  fi
}

save_and_set_secure_setting() {
  key="$1"
  value="$2"
  state_file="$3"
  if [ ! -f "$state_file" ]; then
    settings get secure "$key" > "$state_file" 2>/dev/null
    chmod 0600 "$state_file"
  fi
  if settings put secure "$key" "$value" >> "$LOG_FILE" 2>&1; then
    log "已设置安全设置：$key=$value"
  else
    log "设置失败：$key=$value"
  fi
}

restore_secure_setting() {
  key="$1"
  state_file="$2"
  if [ -f "$state_file" ]; then
    value="$(cat "$state_file")"
    if [ "$value" = "null" ] || [ -z "$value" ]; then
      settings delete secure "$key" >> "$LOG_FILE" 2>&1
    else
      settings put secure "$key" "$value" >> "$LOG_FILE" 2>&1
    fi
    rm -f "$state_file"
    log "已恢复安全设置：$key"
  fi
}

if [ "$DEVICE" != "pudding" ]; then
  log "已跳过：不支持的设备 '$DEVICE'。"
  exit 0
fi

while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 1
done
sleep 5

# shellcheck disable=SC1090
[ -f "$CONFIG" ] && . "$CONFIG"

# ---------- 1) 开机后核对四份音效文件 ----------
for path in /odm/etc/audio/audio_effects_config.json /odm/etc/dolby/dax-default.xml /odm/etc/dolby/dax-default-spatializer.xml /odm/etc/audio_policy_engine_stream_volumes_mi.xml; do
  if cmp -s "$MODDIR/system$path" "$path" 2>/dev/null && ls -Zd "$path" 2>/dev/null | grep -q "u:object_r:vendor_configs_file:s0"; then
    log "调音文件与读取标签校验通过：$path"
  else
    log "调音文件或读取标签校验失败：$path"
  fi
done

# ---------- 2) 类哈曼听感属性 ----------
# v4 的回退验证并未消除高音量断层，反而失去了用户更认可的听感；v4.1 因此
# 使用 profile 3。它只切换本机已有的原厂档位，不添加音效库或后台进程。
if [ "$ENABLE_DOLBY_MUSIC" = "1" ]; then
  case "$DOLBY_PROFILE" in
    0|1|2|3|4|5)
      save_and_set_property "persist.audio.dolby.profile" "$DOLBY_PROFILE" "$DOLBY_STATE_FILE"
      log "已启用原厂 Dolby 音乐档：$DOLBY_PROFILE"
      ;;
    *) log "已拒绝 DOLBY_PROFILE=$DOLBY_PROFILE；仅允许 0 至 5。" ;;
  esac
else
  restore_property "persist.audio.dolby.profile" "$DOLBY_STATE_FILE"
fi

# 使用 MiSound 音乐状态，但不携带任何小米10S库、资源或硬件校准文件。
MISOUND_CONFIG="/vendor/etc/audio/sku_canoe/audio_effects_config.xml"
if [ "$ENABLE_MISOUND_MUSIC" = "1" ] && [ -r "$MISOUND_CONFIG" ] && grep -q 'name="misoundfx"' "$MISOUND_CONFIG"; then
  save_and_set_property "persist.vendor.audio.sfx.hd.music.state" "1" "$MISOUND_STATE_FILE"
  log "已启用原厂 MiSound 音乐状态。"
else
  restore_property "persist.vendor.audio.sfx.hd.music.state" "$MISOUND_STATE_FILE"
  if [ "$ENABLE_MISOUND_MUSIC" = "1" ]; then
    log "未确认原厂 misoundfx，跳过 MiSound 音乐状态。"
  fi
fi

# MiSound APK 包含 persist.vendor.audio.3dsurround.enable、
# set3DSurroundEnable 和 setSpatialAudioEffect。v5 起默认不再锁定空间声总开关，
# 分档修复无需依赖这个实验性开关；若开启，仅固定开关，不轮询、不改内部参数。
if [ "$ENABLE_SPATIAL_ANCHOR" = "1" ]; then
  save_and_set_property "persist.vendor.audio.3dsurround.enable" "1" "$SPATIAL_PROP_STATE_FILE"
  save_and_set_secure_setting "spatial_audio_feature_enable" "1" "$SPATIAL_SETTING_STATE_FILE"
  log "已启用 MiSound 空间声状态保持。"
else
  restore_property "persist.vendor.audio.3dsurround.enable" "$SPATIAL_PROP_STATE_FILE"
  restore_secure_setting "spatial_audio_feature_enable" "$SPATIAL_SETTING_STATE_FILE"
fi

log "已启动：设备=$DEVICE。"
log "已完成：Dolby 调音配置已覆盖；音效库、DSP 固件与扬声器保护未改。"

# ---------- 3) 生成自检报告（用户可在 /sdcard/Download 直接查看） ----------
# 外部存储晚于 boot_completed 就绪时，有限等待后再生成报告。
report_wait=0
while [ ! -w /sdcard/Download ] && [ "$report_wait" -lt 60 ]; do
  sleep 1
  report_wait=$((report_wait + 1))
done
if [ -f "$MODDIR/selfcheck.sh" ] && sh "$MODDIR/selfcheck.sh" >>"$LOG_FILE" 2>&1; then
  log "自检报告已生成。"
else
  log "自检报告生成失败；请检查外部存储和模块执行状态。"
fi
