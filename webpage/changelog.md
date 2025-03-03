# Bloatware Slayer / 干掉预装软件
A Magisk module to remove bloatware in systemlessly way / 一个无需修改 system 分区即可移除预装软件的 Magisk 模块

## Changelog / 变更日志

## 1.1.0

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

## 已确认不会添加的功能：检测包名 / Detecting packages name is permanently off the table

原因如下：/ The reason are as follows:

- 该功能需要添加额外的内置组件：aapt，这会增大维护难度
- The feature requires adding an additional built-in component: aapt, which would increase the maintenance difficulty
- 即使添加了aapt，对基于AOSP的ROM还好说，对于HyperOS、MIUI这类原厂系统动辄100多甚至200多系统应用的来说，逐个扫描apk的包名会严重拖累系统启动速度并消耗大量资源
- Even with aapt added, while it might be okay for ROMs based on AOSP, for stock ROMs like HyperOS and MIUI, which have over 100 or even more than 200 system apps, scanning the package names of each APK individually would severely slow down the system boot speed and consume a large amount of resources
- 既然都能拿到包名了，拿到所在的资源目录自然也不难，添加包名检测事实上也并没有多方便
- Moreover, if the package name can be obtained, it would naturally not be difficult to get the resource directory it is located in. Therefore, adding package name detection does not offer much convenience.

## 已知问题 / Known bug

- 在 KernelSU 中的，哪怕只需要执行一次，挂载阶段的日志输出会重复很多次，但是在 Magisk 并没有这个问题。我推断这可能是 KernelSU 特有的问题，并且目前没有修复它的想法。
- The output of logs in mounting stage will repeat many times even if only need to execute one time in KernelSU. But there is no such problem in Magisk. I infer that this problem maybe **unique to KernelSU (KernelSU only)** and have no idea to do about it so far.

## 1.0.9

- 现在的模块描述中，移除的显示优先级比禁用高
- Now the priority of status remove showing in module description is higher than disable
- 降低模块描述刷新频率至3秒以减少CPU开销
- Reduce module description refresh rate to 3 seconds to decrease CPU overhead
- 不再自动生成安装日志，请手动从 Magisk / KernelSU 处导出
- No more install log automatically, please export it from Magisk / KernelSU manually
- 优化日志输出，移除部分不必要的代码
- Optimize log output and remove some unnecessary code

## 1.0.8

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
