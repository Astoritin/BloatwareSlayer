[English](README.md) | 简体中文

# **干掉预装软件 / Bloatware Slayer**
一个无需修改 system 分区即可移除预装软件的 Magisk 模块 / A Magisk module to remove bloatware systemlessly

## 支持的 Root 方案
[Magisk](https://github.com/topjohnwu/Magisk) (推荐!) 丨 [KernelSU](https://github.com/tiann/KernelSU) (推荐!) 丨 [APatch](https://github.com/bmax121/APatch) (仅理论上支持，未经实际测试)

## 步骤
Bloatware Slayer 通过 Magisk、KernelSU 和 APatch 的特定挂载方法，以 Systemless 的方式删除预装软件，以下是大致步骤：
1. 安装 Magisk / KernelSU / APatch
2. 下载并安装本模块
3. 使用 [App Manager](https://github.com/MuntashirAkon/AppManager) 查找想要删除的系统应用名，点击进入并复制资源目录 (若不以 `/system` 开头请手动添加)，或使用Root Explorer、MiXplorer之类的Root 文件管理器在 `/system` 处手动寻找并复制预装软件所在的目录名
4. 打开 `/data/adb/bloatwareslayer/target.conf`，并将你通过步骤3获得的预装软件所在的目录名放在上面，**一行一个**
5. 保存 target.conf 的更改，并重新启动后查看效果
> 例如：我需要卸载小爱同学，那么我会通过 AppManager 查看小爱同学所在的文件夹，得知其名字是 `VoiceAssistAndroidT`，然后将 `VoiceAssistAndroidT` 复制到 `target.conf` ，回车并保存更改后重启设备。

## 注意
1. `target.conf` 支持"#"号注释整行和项目旁存在注释，Bloatware Slayer 不会处理被注释掉的行和空行。
2. Bloatware Slayer 支持自定义路径，例如：`/system/app/MiVideo`。此时 Bloatware Slayer 会直接处理该自定义路径而不会再扫描其他系统文件夹。
3. ~~由于现如今绝大多数设备都是 SAR (System-as-root)，你可能在 AppManager 中看到的资源目录名不是 `/system` 开头 (例如  `/product/app/Scanner`)，为了确保挂载生效，请手动在这类路径前面添加 `/system` ，否则 Bloatware Slayer 会直接忽略该路径。~~
> 自 `1.4.1` 起，Bloatware Slayer 支持自动添加 `/system`，不再强制要求添加 `/system`。
> 如果 `target.conf` 中存在条目 `/system`，那么该条目会被忽略。
4. 为了节省时间和减少资源消耗，现在`target.conf`会随着每次系统启动自动更新为预装APP对应的系统目录，你可以查阅“配置文件”部分进行了解。
5. 若你看到的资源目录以 `/data` 开头，则说明该APP是安装完ROM后的第一次初始化安装上的，实质上属于用户应用，只是内置于ROM的刷机包的特定目录，不属于目前 Root 方案能直接干涉的范畴。这类应用可以自行卸载，并且只有恢复出厂设置时才可能重新被自动安装，请不要加入到 `target.conf` 中，因为Bloatware Slayer的处理也不会对这类软件生效。

## 配置文件
自 v1.2.1 起， Bloatware Slayer 支持手动启用或禁用以下功能，如有需求请打开配置文件`/data/adb/bloatwareslayer/settings.conf`查看并修改。

1. **`brick_rescue`**：设定是否启用模块内置的救砖模式，默认情况下为`true`。
> 若设定 `brick_rescue=false`，则在检测到无法开机时，Bloatware Slayer不会采取任何行动。
2. **`brick_timeout`**：设定判断设备变砖的时限(Timeout)，要求正整数，以秒为单位。
> 如果不在`settings.conf`中指定，则默认值是`300`秒(5分钟)。
3. **`disable_module_as_brick`**：设定是否在触发设备变砖时自动禁用该模块。默认情况下为`true`(启用)，你也可以设置为`false`以禁用该功能。
> 当启用时，模块会在触发救砖模式时自我禁用以防止潜在问题。若禁用，则模块在检测到设备变砖时就**只会跳过挂载而不会自我禁用**，在排除`target.conf`中的不稳定项目后即可自行重新启动，无需再进入Root管理器重新启用本模块。
4. **`last_worked_target_list`**：最后一次正确目标列表，Bloatware Slayer 会备份最新的能够启动系统的 `target.conf`，并在检测到设备无法开机时尝试恢复该列表文件并重新启动设备，默认情况下为`true`(启用)。
> 该选项与 `disable_module_as_brick` 无法同时启用，若启用 `disable_module_as_brick` 则 `last_worked_target_list`(最后一次正确目标列表) 功能在逻辑上无法生效。
5. **`slay_mode`**: Bloatware Slayer 屏蔽预装软件的方式。
- `MB` (Mount Bind), 是在绝大多数ROM内的各种Root方案通用的方法。
- `MR` (Magisk Replace), 是 Magisk 专用的方法。
- `MN` (Make Node), 是 Magisk 28102+、KernelSU 和 APatch 可用的方法。
> 在`settings.conf`中，默认值为 `MB` (Mount Bind)，因为该方案兼容性最高。
6. **`mb_umount_bind`**: 当 `slay_mode` 被设定为 `MB` (Mount Bind) 且该选项被启用时，Bloatware Slayer 会卸载由自身创建的挂载点，进而隐藏被处理的痕迹，默认情况下为`true`(启用)。
> 正常情况下无需修改该选项的状态。
7. **`system_app_paths`**: 自定义扫描预装软件所在的系统目录，路径以`/`开头，用空格隔开。
> 例如`system_app_paths=/system/app /system/priv-app`
8. **`auto_update_target_list`**：每次启动时是否更新 target.conf 中的项目为预装应用所在路径，默认情况下为`true`(启用)以加快下次系统的启动速度。
> 如果你不希望自己在 `target.conf` 中编辑的内容(例如注释或者保留未找到的项目)被模块自动更新覆盖掉，则可以设定为`false`。
9. **`update_desc_on_action`**：实时更新 Magisk 和 Zygisk Next 的遵守排除列表的功能启用状态，以及在模块被禁用/卸载时更新模块状态描述，默认情况下为`true`(启用)。

## 常见问题
请参阅 [Q&A](Q&A_ZH-CN.md) 。

## 日志
日志被保存在 `/data/adb/bloatwareslayer/logs`，你可以查看它并在反馈遇到的问题时提交该日志。

**反馈问题时，请直接打包整个logs文件夹后上传。**

## 救砖
Bloatware Slayer 内置救砖机制，当检测到手机启动时间过长，会自动禁用模块的挂载功能并自动重启。重启后，你会在模块状态上看见相应信息，请自行调整 `target.conf` ，删除不该被禁用的项目后重新启动
默认的等待时长是300秒（5分钟），也就是说 Bloatware Slayer 会在等待5分钟后自我禁用并重新启动。
若你的系统正在更新，请临时禁用或卸载该模块，之后再安装。

## 经过测试的ROM
1. 小米澎湃系统2.0.105.0，安卓15，设备：红米 Note 9 Pro 5G 8+256GB (设备代号gauguin，移植系统)
- Root：Magisk Alpha 28102,28103,28104,29001
2. 小米MIUI12.5.4，安卓10，设备：红米 Note 7 Pro 6+128GB (设备代号violet，原厂系统)
- Root：Magisk Alpha 28102,28103,29001
3. DroidUI-X，安卓14，设备：红米 Note 7 Pro 6+128GB (设备代号violet，类原生系统)
- Root: KernelSU with Magic Mount 1.0.3
- Root: KernelSU with OverlayFS 0.9.5
4. Flyme 8.0.5.0A, 安卓7.1.2, 设备: 魅蓝 Note 6 4+64GB (设备代号m1721, 原厂系统)
- Root: Magisk Lite 25205
5. Derpfest 15.1 Stable，安卓15，设备：红米 Note 7 Pro 6+128GB (设备代号violet，类原生系统)
- Root: Magisk Alpha 28103,28104,29001

## 帮助与支持
- 如果遇到问题，请点击 [此处](https://github.com/Astoritin/BloatwareSlayer/issues) 提交反馈
- 欢迎 [提交代码](https://github.com/Astoritin/BloatwareSlayer/pulls)，让该模块变得更好

## 鸣谢
- [Magisk](https://github.com/topjohnwu/Magisk) - 让一切皆有可能的基石
- [Zygisk Next](https://github.com/Dr-TSNG/ZygiskNext) - extract和root方案检查函数实现
- [LSPosed](https://github.com/LSPosed/LSPosed) - extract和root方案检查函数实现
