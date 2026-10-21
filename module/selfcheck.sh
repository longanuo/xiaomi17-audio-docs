#!/system/bin/sh
MODDIR=${0%/*}
OUT=/sdcard/Download/xiaomi17_audio_mod_selfcheck.txt
TMP="$OUT.tmp"
{
  echo "小米17外放音量衔接 v1.5.6"
  echo "时间：$(date)"
  echo "设备：$(getprop ro.product.device)"
  echo "系统：$(getprop ro.build.version.incremental)"
  echo "注意：文件相同仅证明本脚本视图中的覆盖，不证明引擎已加载参数。"
  for path in /odm/etc/audio/audio_effects_config.json /odm/etc/dolby/dax-default.xml /odm/etc/dolby/dax-default-spatializer.xml /odm/etc/audio_policy_engine_stream_volumes_mi.xml; do
    if cmp -s "$MODDIR/system$path" "$path" 2>/dev/null; then
      echo "文件一致：$path"
    else
      echo "文件不一致或不可读：$path"
    fi
    echo "目标文件标签："
    ls -lZ "$path" 2>&1
    echo "模块源文件标签："
    ls -lZ "$MODDIR/system$path" 2>&1
    sha256sum "$path" 2>&1
  done
  echo "开机挂载标记：$(cat /data/adb/xiaomi17_audio_mod_stage1 2>/dev/null)"
  echo "音频服务（无媒体播放时不作听感判断）："
  dumpsys audio 2>/dev/null | grep -E 'Spatializer status|Dolby current params|Dolby spatializer current params|streamVolume:|isSpatializerEnabled:'
  echo "音量策略来源与实际媒体曲线（需核对，文件覆盖不等于策略加载）："
  dumpsys media.audio_policy 2>/dev/null | sed -n '/Config source:/p; /    -music (id:/,/    -assistant (id:/p'
  echo "系统内的抖音应用音量系数（不等于播放器音轨增益）："
  dumpsys audio 2>/dev/null | grep 'pkg=com.ss.android.ugc.aweme volume='
  echo "空间处理与调音日志："
  logcat -d -v brief 2>/dev/null | grep -E 'not a valid tuning device|tuningDevice.*not available|DlbSpatializer.*(process\(\)|[Tt]uning|[Cc]onfig)' | tail -20
  echo "本次开机的 Dolby 配置访问拒绝："
  logcat -b all -d -v brief 2>/dev/null | grep -E "avc:.*(dax-default|audio_policy_engine_stream_volumes_mi)" | tail -12
  echo "SELinux 状态：$(getenforce)"
  echo "模块日志："
  tail -30 /data/adb/xiaomi17_stock_safe_audio.log 2>&1
} > "$TMP" 2>&1
if [ -s "$TMP" ]; then
  mv "$TMP" "$OUT"
  chmod 0644 "$OUT" 2>/dev/null
else
  echo "自检输出失败：Download 可能尚未就绪" >&2
  exit 1
fi
echo "自检报告：$OUT"
