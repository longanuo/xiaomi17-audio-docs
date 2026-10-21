# 开发者打包说明

安装使用可直接下载 [Releases 中的 v1.5.6 模块 ZIP](https://github.com/longanuo/xiaomi17-audio-docs/releases/download/v1.5.6/xiaomi17-audio-v1.5.6.zip)。以下步骤用于修改源码后自行生成安装包。

## 源码目录

[`module/`](../module/) 包含从原始 `xiaomi17-audio-v1.5.6.zip` 提取的全部 15 个文件，包括安装、挂载、服务、自检、诊断、卸载脚本和四份音频配置。

导入时逐文件保留原始内容；仓库的 `.gitattributes` 禁止 Git 自动转换这些文件的换行符。初次导入的源码内容与原始发布包逐字节一致。

## 生成安装包

电脑安装 Python 3.9 或以上版本后，在仓库根目录执行：

```shell
python tools/build_module.py
```

Windows 也可以使用 Python 启动器：

```shell
py -3 tools/build_module.py
```

[`tools/build_module.py`](../tools/build_module.py) 仅使用 Python 标准库，不需要第三方依赖。输出文件为 `dist/xiaomi17-audio-v1.5.6.zip`，`dist/` 不纳入 Git 提交。

脚本会检查必需文件、JSON/XML 格式、ZIP CRC 和包内文件一致性，并保证 `module.prop` 位于 ZIP 根目录。完整仓库的 “Download ZIP” 下载的是源码，模块管理器需要使用打包脚本生成的安装包。

## 校验与发布

重新打包使用固定时间戳和文件权限，因此生成的 ZIP 哈希可能与原始发布包不同。即使所有解压后的文件一致，压缩文件的元数据和压缩参数也可能造成哈希差异。脚本会打印实际生成文件的 SHA-256；上传新附件时应使用该文件对应的校验值。

现有 v1.5.6 Release 使用原始安装包，其大小为 24,481 字节，SHA-256 为：

```text
34916f945a53f821370f54c94230ed74266a3d6342ad30b05f047a10dbcd14e2
```

修改版本时，应同步更新 `module/module.prop`、脚本中的版本提示、方案说明和发布文案。打包与文件一致性检查只覆盖电脑端检查，实机安装、加载和听感需要另行验证。
