## Bloatware Slayer / 干掉预装软件
A Magisk module to remove bloatware in systemlessly way / 一个无需修改 system 分区即可移除预装软件的 Magisk 模块

### Changelog / 变更日志

### 1.2.7

- Add action.sh as shortcut to open the config directory with root file managers
- 新增 `action.sh` 以便于快捷用 `Root` 文件相关的管理器打开配置文件目录
- Add old version migration feature in flashing / installing process to clean the remnant files by old versions
- 在安装过程中增加旧版本迁移功能以对部分旧版本残留文件进行清理
- SHA256: `698ab12d45d18ff4ea1cb1b4cddedf5b7c6b209fe465adeecf01b562ff143fbf`

### 1.2.6

- Add the security check for config file / 增加对配置文件的安全检查
- Remove Bash ONLY code and enhance the compatibility for POSIX shell / 移除 Bash 专属代码，增强了对 POSIX shell 的兼容性
- Several minor changes / 若干细微改动
- SHA256: `a5dabd9930752c24d10ed8bc87930a4b6e79578fdb24079d09a63553e0c06e37`

### 1.2.5

- Remove some redundant code
- 移除部分冗余代码
- Optimize log output
- 优化日志输出
- SHA256: `bd70a8317a3b19edafba3d3ba2312ef56e5dd37a6f9644161878d0a1fb3ef690`

### 1.2.4

- 修复潜在的由于开放自定义扫描预装软件所在系统目录功能导致的安全问题
- Fix the potential security issues arising from the function of customizing the scanning system directories of bloatware

### 1.2.3

- 支持自定义扫描预装软件所在的系统目录，如有需求可手动修改`/data/adb/bloatwareslayer/settings.conf`的`system_app_paths`的值（以/开头，用空格隔开）
- Support customizing the scan of system directories the bloatware located in. If needed, you can manually modify the value of `system_app_paths` in `/data/adb/bloatwareslayer/settings.conf` (starting with `/` and separated by spaces).

### 1.2.2

1. `target.conf` 现在支持文件夹名/目录名旁存在注释，例如：`VoiceAssistantT #超级小爱` / Support comment next to the APP path and APP folder name in `target.conf`
2. 修复部分逻辑永远不会被执行的bug / Fix the bug which caused some logical codes will NOT execute permanently
3. 独立部分日志输出代码为一个函数，提升可维护度 / Separate some logging output codes into a function to improve the maintainability of this module

### 1.2.1

- 支持自定义判定设备变砖的时限，默认为300秒 (5分钟) ，你可以根据你的设备的正常启动时间自行修改该值：`/data/adb/bloatwareslayer/settings.conf`的`brick_timeout`为你想要设定的等待时间 (正整数，单位为秒) 以免造成不必要的等待或误判
- Support for customizing the timeout duration for determining whether the device is bricked. The default value is 300 seconds (5 minutes). You can adjust this value according to your device's normal boot time by setting the `brick_timeout` value  in `/data/adb/bloatwareslayer/settings.conf` to your desired waiting time (a positive integer,in seconds) to avoid unnecessary waiting or misjudgment

- 现在，【模块状态提示跟随禁用/卸载而变化】为可选功能，默认禁用以节省电量和系统资源消耗，如有需求可手动修改`/data/adb/bloatwareslayer/settings.conf`的`update_desc_on_action`为`true`以开启该功能
- Now, the feature of 【module status description changing realtime with disable/uninstall】 is optional. It is disabled by default to save power and system resource consumption. If needed, you can manually enable this feature by setting `update_desc_on_action` to `true` in `/data/adb/bloatwareslayer/settings.conf`

- 现在，【系统启动时自动更新 target.txt 的项目为预装软件所在路径】为可选功能，默认启用以大幅减少下次系统启动时模块所耗费的时间，如不需要或者想要保留自己修改的 target.txt 可手动修改`/data/adb/bloatwareslayer/settings.conf`的`auto_update_target_list`为`false`以关闭该功能
- Now, the feature of 【automatically updating the target.txt entries with bloatware‘s paths at system boot】 is optional. It is enabled by default to significantly reduce the time consumed by the module during the next system startup. If you do NOT need this feature or wish to retain your custom modifications to target.txt, you can manually disable it by setting `auto_update_target_list` to `false` in `/data/adb/bloatwareslayer/settings.conf`

- 现在，【触发救砖模式时自动禁用模块】为可选功能，默认启用以阻止特定情形下用户忘记去除 target.txt 的不稳定项目便直接重启结果发现设备再度"变砖"的情况，如不想每次设备变砖时手动启用模块可手动修改`/data/adb/bloatwareslayer/settings.conf`的`disable_module_as_brick`为`false`以关闭该功能
- Now, the feature of 【automatically disable the module as triggering the brick rescue mode】 is optional. It is enabled by default to prevent the situation where users forget to remove unstable entries from target.txt and directly reboot the device,resulting in the device becoming "bricked" again. If you do NOT want to manually enable the module every time the device becomes bricked, you can disable this feature by setting `disable_module_as_brick` to `false` in `/data/adb/bloatwareslayer/settings.conf`

- 日志输出代码微调以提高日志记录效率
- Minor adjustments to the log output code to improve logging efficiency

### 1.2.0

- Remove unnecessary status.info completely
- 彻底移除不必要的 status.info
- Auto update the available app path in target.txt each time
- 自动更新 target.txt 为有效的应用路径
- Refactor large amount of code and unified logging
- 重构大量代码，统一日志输出
- Fix the unavailable unbrick feature
- 修复失效的救砖功能

### 1.1.0

- Critical change: Abandon post-fs-data.sh completely and migrate the core functions to service.sh, significantly reduce the boot time of staying in splash logo screen caused by Bloatware Slayer.
- 重大变更：彻底抛弃 post-fs-data.sh ，模块的核心功能已被迁移到 service.sh 中，大幅度缩减开机第一屏的等待时间
- No more .replace method for Magisk, significantly reduce the folders generation
- 不再为 Magisk 单独使用 .replace 办法, 极大减少了文件夹的生成
- Now Magisk, KernelSU and APatch use the same method to implement the mount: mount --bind empty
- 现在 Magisk、KernelSU 和 APatch 使用相同的方案以实现挂载： mount --bind 空目录
- The built-in unbrick behavior has changed. Now the module will automatically delete the brick flag file after each time it approaches a brick state and skips mounting, instead of checking the value of `sys.boot_completed`
- 内置救砖行为变更。现在模块会在每次变砖和跳过挂载后自动删除变砖标识符文件，而不是检查`sys.boot_completed`的值
- improve the output of logs
- 优化日志输出

### 已确认不会添加的功能：检测包名 / Detecting packages name is permanently off the table

原因如下：/ The reason are as follows:

- 该功能需要添加额外的内置组件：aapt，这会增大维护难度
- The feature requires adding an additional built-in component: aapt, which would increase the maintenance difficulty
- 即使添加了aapt，对基于AOSP的ROM还好说，对于HyperOS、MIUI这类原厂系统动辄100多甚至200多系统应用的来说，逐个扫描apk的包名会严重拖累系统启动速度并消耗大量资源
- Even with aapt added, while it might be okay for ROMs based on AOSP, for stock ROMs like HyperOS and MIUI, which have over 100 or even more than 200 system apps, scanning the package names of each APK individually would severely slow down the system boot speed and consume a large amount of resources
- 既然都能拿到包名了，拿到所在的资源目录自然也不难，添加包名检测事实上也并没有多方便
- Moreover, if the package name can be obtained, it would naturally not be difficult to get the resource directory it is located in. Therefore, adding package name detection does not offer much convenience.

~~## 已知问题 / Known bug~~

~~- 在 KernelSU 中的，哪怕只需要执行一次，挂载阶段的日志输出会重复很多次，但是在 Magisk 并没有这个问题。我推断这可能是 KernelSU 特有的问题，并且目前没有修复它的想法。~~
~~- The output of logs in mounting stage will repeat many times even if only need to execute one time in KernelSU. But there is no such problem in Magisk. I infer that this problem maybe **unique to KernelSU (KernelSU only)** and have no idea to do about it so far.~~

### 1.0.9

- 现在的模块描述中，移除的显示优先级比禁用高
- Now the priority of status remove showing in module description is higher than disable
- 降低模块描述刷新频率至3秒以减少CPU开销
- Reduce module description refresh rate to 3 seconds to decrease CPU overhead
- 不再自动生成安装日志，请手动从 Magisk / KernelSU 处导出
- No more install log automatically, please export it from Magisk / KernelSU manually
- 优化日志输出，移除部分不必要的代码
- Optimize log output and remove some unnecessary code

### 1.0.8

- 现在，当`/data/adb/bloatwareslayer/logs`下的日志过多，Bloatware Slayer会在安装或更新过程中清除较早的日志
- Bloatware Slayer will clean old logs in updating or installing if there are too many files under the folder `/data/adb/bloatwareslayer/logs`
- 新增扫描的系统预装软件目录：<br>`/system/vendor/app`<br>`/system/vendor/priv-app`<br>
- Add new system pre-install directories: <br>`/system/vendor/app`<br>`/system/vendor/priv-app`<br>

### 1.0.7

- Support custom directory (add "/system/(custom dir name)/(custom dir name)" to target.txt)
- 支持自定义目录 (添加 "/system/(自定义目录名称)/(自定义目录名称)" 至target.txt)
- Now, you can order the dirs of bloatware you want to block manually
- 现在，你可以手动设定你想要阻止的预装软件所在路径 
- Now Bloatware Slayer will ignore space/blank before the text per line
- 现在，Bloatware Slayer 会无视每行文本前的空格
- Bloatware Slayer will correct the wrong symbol \ in dir in target.txt automatically
- Bloatware Slayer 会自动纠正在 target.txt 中的路径被错误使用的转义符号
- Root implementation in module description will be updated in booting system each time
- 模块描述中的 Root 方案会在每次系统启动时更新
- Module Status will be updated real time as removing or disabling module
- 当移除或禁用模块时，模块状态会实时更新
- Add integrity verification to prove that the module has not been maliciously modified
- 新增完整性验证以证明模块未被恶意修改

### 1.0.5
- Support KernelSU officially
  正式支持 KernelSU
- Change the method of processing Apps in KernelSU and APatch
  from mknod to mount -o bind to improve compatibility
  更改在 KernelSU 和 APatch 中处理 APP 的方式
  从 mknod 变为 mount -o bind 以提升兼容性
- Optimize logic for some code
  优化部分逻辑
- Optimize the module status prompt content
  优化模块状态提示内容

### 1.0.3
- Add simple inbuilt unbrick method
  新增简易的内置救砖方法
  Bloatware Slayer will reboot and skip mounting this module next time  
  if booting fails in **300** seconds.  
  Please check target list in `/data/adb/bloatwareslayer/target.txt`  
  and delete the items may caused brick.
  现在如果系统在**300秒**后仍未完成启动，  
  模块会自行重新启动并在下次启动时跳过挂载该模块  
  请检查`/data/adb/bloatwareslayer/target.txt`的列表
  并删除可能会导致变砖的项目  

- Optimize logic for some code
  优化部分逻辑
- Improve the module status prompt content
  优化模块状态提示内容

### 1.0.2
- Optimize the judgment logic to reduce bugs caused by some extreme cases.
  优化判断逻辑，减少部分极端情况导致的bug
- Improve the module status prompt content
  优化模块状态提示内容

### 1.0.0
- Initial build / the first page
  第一页
