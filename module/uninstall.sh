#!/system/bin/sh
# 卸载时恢复安装模块前的持久音效状态；不会触碰系统文件。
restore_property() {
  property="$1"
  state_file="$2"
  if [ -f "$state_file" ]; then
    setprop "$property" "$(cat "$state_file")"
    rm -f "$state_file"
  fi
}
restore_property "persist.audio.dolby.profile" "/data/adb/xiaomi17_stock_safe_audio_dolby_original"
restore_property "persist.vendor.audio.sfx.hd.music.state" "/data/adb/xiaomi17_stock_safe_audio_misound_music_original"
restore_property "persist.vendor.audio.3dsurround.enable" "/data/adb/xiaomi17_stock_safe_audio_3dsurround_original"
if [ -f "/data/adb/xiaomi17_stock_safe_audio_spatial_setting_original" ]; then
  value="$(cat "/data/adb/xiaomi17_stock_safe_audio_spatial_setting_original")"
  if [ "$value" = "null" ] || [ -z "$value" ]; then
    settings delete secure spatial_audio_feature_enable >/dev/null 2>&1
  else
    settings put secure spatial_audio_feature_enable "$value" >/dev/null 2>&1
  fi
  rm -f /data/adb/xiaomi17_stock_safe_audio_spatial_setting_original
fi
# 挂载由模块管理器在重启时清理；不在卸载脚本中卸载别的模块可能共用的挂载点。
rm -f /data/adb/xiaomi17_audio_mod_stage1
rm -f /data/adb/xiaomi17_stock_safe_audio.log
