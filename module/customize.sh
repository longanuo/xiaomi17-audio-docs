#!/system/bin/sh
DEVICE="$(getprop ro.product.device)"
ui_print "小米17外放音效 v1.5.6；作者：林河"
[ "$DEVICE" = "pudding" ] || abort "仅适用于小米17标准版 pudding；当前设备：$DEVICE"
ui_print "机型校验通过：$DEVICE；不限制系统版本"
ui_print "当前系统（仅供记录）：$(getprop ro.build.version.incremental)"
for rel in /odm/etc/audio/audio_effects_config.json /odm/etc/dolby/dax-default.xml /odm/etc/dolby/dax-default-spatializer.xml /odm/etc/audio_policy_engine_stream_volumes_mi.xml; do
  [ -f "$MODPATH/system$rel" ] || abort "缺少调音文件：$rel"
done
set_perm_recursive "$MODPATH" 0 0 0755 0644
for f in service.sh post-fs-data.sh selfcheck.sh action.sh diagnose.sh uninstall.sh; do
  [ -f "$MODPATH/$f" ] && set_perm "$MODPATH/$f" 0 0 0755
done
# 保留原有配置权限与标签校验；不检查 ROM 版本或配置白名单。
for rel in /odm/etc/audio/audio_effects_config.json /odm/etc/dolby/dax-default.xml /odm/etc/dolby/dax-default-spatializer.xml /odm/etc/audio_policy_engine_stream_volumes_mi.xml; do
  file="$MODPATH/system$rel"
  chcon u:object_r:vendor_configs_file:s0 "$file" || abort "配置标签设置失败：$rel"
  ls -Zd "$file" | grep -q 'u:object_r:vendor_configs_file:s0' || abort "配置标签校验失败：$rel"
done
ui_print "原厂配置读取标签已设置并校验"
ui_print "沿用 v1.5.4 沉浸声、鼓点调音和中低音量补偿"
ui_print "安装完成，请重启；再核对自检报告与实际听感"
