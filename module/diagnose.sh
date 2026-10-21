#!/system/bin/sh
# 仅 root 可运行的诊断脚本；可由 action.sh 或手动调用。

MODDIR=${0%/*}
OUT="/sdcard/Download/xiaomi17_stock_safe_audio_diagnose.txt"

find_tinymix() {
  for candidate in /vendor/bin/tinymix /system/bin/tinymix /system_ext/bin/tinymix; do
    [ -x "$candidate" ] && { echo "$candidate"; return 0; }
  done
  command -v tinymix 2>/dev/null
}

{
  echo "小米17类哈曼音质音效 v1.5.6：诊断报告"
  echo "时间：$(date)"
  echo "设备：$(getprop ro.product.device)"
  echo "版本：$(getprop ro.build.display.id)"
  echo
  echo "=== 模块配置 ==="
  cat "$MODDIR/audio_tuning.conf" 2>&1
  echo
  echo "=== 类哈曼 / 音效属性 ==="
  getprop ro.vendor.audio.sfx.harmankardon
  getprop persist.vendor.audio.sfx.hd.music.state
  getprop persist.audio.dolby.profile
  getprop persist.vendor.audio.3dsurround.enable
  settings get global spatial_audio_feature_enable 2>&1
  echo
  echo "=== 最近空间声状态广播 ==="
  dumpsys activity broadcasts 2>&1 | grep -Ei -C 1 'ACTION_AUDIO_EFFECT_REFRESH|spatial_active' | tail -80
  echo
  echo "=== 生效的扬声器音量分档 ==="
  cat /odm/etc/audio/audio_effects_config.json 2>&1
  echo
  echo "=== 相关 mixer 控制项 ==="
  TINYMIX="$(find_tinymix)"
  if [ -n "$TINYMIX" ]; then
    "$TINYMIX" 2>&1 | grep -Ei 'SA1 FU21|WSA_|HPHL Volume|HPHR Volume|RX_RX[01] Digital|RX HPH Mode|Softclip|IIR' || true
  else
    echo "未找到 tinymix"
  fi
  echo
  echo "=== 模块日志 ==="
  tail -80 /data/adb/xiaomi17_stock_safe_audio.log 2>&1
} > "$OUT"

chmod 0644 "$OUT"
echo "诊断报告已保存至：$OUT"
