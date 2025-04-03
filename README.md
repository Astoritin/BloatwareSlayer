English | [简体中文](README_ZH-SC.md)

# **Bloatware Slayer / 干掉预装软件**

A Magisk module to remove bloatware in systemlessly way / 一个无需修改 system 分区即可移除预装软件的 Magisk 模块

![Bloatware Slayer](webpage/img/bs_work_allclear.png)

## Supported Root Solution

[Magisk](https://github.com/topjohnwu/Magisk) (Recommended!) 丨 [KernelSU](https://github.com/tiann/KernelSU) (Recommended!) 丨 [APatch](https://github.com/bmax121/APatch) (Not test yet)

## Details

Bloatware Slayer removes bloatwares in systemless way, using specific mount methods from Magisk, KernelSU and APatch. Below are the steps:

1. Install Magisk / KernelSU / APatch
2. Download and install Bloatware Slayer
3. To obtain the directories of bloatwares, you need to do some research beforehand: For example, use [App Manager](https://github.com/MuntashirAkon/AppManager), Root Explorer, or MiXplorer to manually locate and copy the folder names of pre-installed apps under `/system`.
4. Open the file `/data/adb/bloatwareslayer/target.conf` and add the directories of the bloatwares obtained in step 3, **one per line**.
5. Save the changes to `target.conf` and reboot your device to observe the results.

You can see the information of blocked APPs (slain), APPs not found (missing) and APPs in total (targeted in total) in the module description.

![Bloatware Slayer](webpage/img/bs_work_normal.png)

For example, I need to uninstall XiaoAi Voice Assistant, so I will get the folder XiaoAi Voice Assistant located in by AppManager and soon get its name `VoiceAssistAndroidT`, then copy `VoiceAssistAndroidT` and add it into `target.conf` , save the changes and reboot my device.

## NOTICE

1. `target.conf` supports commenting out entire lines with the "#" symbol. Bloatware Slayer will ignore commented lines and empty lines.
2. Bloatware Slayer supports custom paths, for example: `/system/app/MiVideo`. In this case, Bloatware Slayer will directly process the custom path without scanning other system folders.
3. Since most modern devices use SAR (System-as-root), the resource directory names you see in AppManager may not start with `/system` (for example, `/product/app/Scanner`). To ensure the mount works, you need to add `/system` manually to the beginning of paths. Otherwise, Bloatware Slayer will ignore them.
4. To save the time and reduce the cost of resources, now Bloatware Slayer will update the items of `target.conf` into the system path bloatwares located in automatically in each time booting. You can read the chapter `Config File` to know.
5. If the resource directory starts with `/data`, it means the app was installed as first booting after the initial of ROM setup. You can uninstall it manually and should NOT add it to `target.conf`, as Bloatware Slayer's processing will not affect such apps.

### Q: Why do I need to manually copy the folder names instead of letting the module detect the system directories based on the app names or package names?

1. **Firstly, the APP name and package name are not reliable, and relying on these two factors to locate the APP folder is extremely inefficient.**
For most standardized ROMs, the probability of using languages other than English to name system directories/folders is extremely low.  
Moreover, there are quite a few APPs whose APP names have no relation to their system directory/folder names (whether due to the ROM provider's carelessness and lack of proficiency leading to non-standard naming details, or the sinister intentions of some apps that deliberately use non-standard naming to hide their user data collection activities). If one insists on matching them in this way, not only would a large amount of data analysis be required, but the error rate would still be quite high.  

*For example, there is an app named "System Service," but its directory/folder name is "AdPushService," and its package name is "com.android.adpromote."*  

2. Regarding package names, please refer to [**"Confirmed feature that will not be added: Detecting package names is permanently off the table"**](https://github.com/Astoritin/Bloatware_Slayer/issues/6#issuecomment-2693035556).  

3. **Besides, although this module operates in a Systemless (non-system-modifying) manner, you must always know and be certain of what you are doing.** You need to know which system apps you should disable, **instead of blindly copying someone else's list and then shifting all the blame to this Magisk module when problems arise.**


## Configuration File

Starting from version v1.2.1, Bloatware Slayer supports manually enabling or disabling the following features. Please open the configuration file `/data/adb/bloatwareslayer/settings.conf` to view and modify the settings if needed. If not specified in the `settings.conf` file, the default value is `300` seconds (5 minutes). However, the default value within the `settings.conf` file is `180` seconds (3 minutes).

1. **`brick_timeout`**: Sets the timeout for determining if the device has bricked. It requires a positive integer, measured in seconds. The default value is `300` seconds (5 minutes).
If it is not set in `settings.conf`, the default value is `300 seconds (5 minutes)`, the default value in `settings.conf` is `180 seconds (3 minutes)`.

2. **`disable_module_as_brick`**: Determines whether the module should automatically disable itself when the device is detected as bricked. By default, it is set to `true` (enabled), but you can set it to `false` to disable this feature.  
When enabled, the module will disable itself to prevent further issues. If you set it to `false`, the module will only skip mounting without disabling itself. This allows you to troubleshoot and reboot the system after removing unstable items from `target.conf`, without needing to re-enable the module via Root manager manually.

3. **`auto_update_target_list`**: Control the behavior whether to update the items in `target.conf` to the paths of bloatwares apps during each startup. By default, it is set to `true` (enabled) to speed up system startup.
If you prefer to keep your custom comments or retain items in `target.conf` that were not found by the module, you can set this to `false`.

4. ~~**`update_desc_on_action`**: Updates the module status description when the module is disabled or uninstalled. This is a mostly useless feature that increases resource consumption and is disabled(`false`) by default.~~
~~If you want to see a prompt when you click the disable or uninstall button, you can set this to `true` to enable the feature.~~
**NOTICE: This feature has been removed since 1.2.8**

5. **`system_app_paths`**: Support customizing the scan of system directories the bloatware located in. Paths starts with `/` and separated by spaces, for example: `system_app_paths=/system/app /system/priv-app`.

6. **`slay_mode`**: the method of Bloatware Slayer blocking bloatwares.
`MB (Mount Bind)`, a method that is generally applicable to various Root solutions in most ROMs.  
`MR (Magisk Replace)`, a method specific to Magisk.  
`MN (Make Node)`, a method available for Magisk 28102+、KernelSU, and APatch.

In `settings.conf`, the default value of Bloatware Slayer is `MB` (Mount Bind), since the method has the highest compatibility——even though it is not so good in Root hiding. You may switch into MR mode or MN mode manually if needed, which is more friendly for Root hiding.

## Logs

Logs are saved in `/data/adb/bloatwareslayer/logs`, you can review them and submit them when reporting issues. 

### Notice

`bs_log_core_(timestamp).log` is the logs about core features of Bloatware Slayer. 
Since the system is not fully initialized at this stage, the date you see might appear very strange. Please do not be concerned.
`bs_log_bricked_(timestamp).log` is the logs about unbrick detection feature of Bloatware Slayer.
`bs_log_action_(timestamp).log` is the logs about action button of Bloatware Slayer.
**When reporting issues, please simply zip the entire logs folder and upload it.**

## Unbrick

Bloatware Slayer has a built-in brick recovery method. If the device takes too long to boot, it will automatically disable the module's mounting functionality and reboot.
After rebooting, you will see a message in the module status.
Please adjust `target.conf` by removing entries that should not be disabled and reboot again.
The default wait time is 300 seconds (5 minutes), meaning Bloatware Slayer will disable itself and reboot after waiting for 5 minutes.If your system is updating, temporarily disable or uninstall this module and reinstall it later is recommended.

### Q: Will Bloatware Slayer damage my device? Why need to learn unbrick skills?

Primarily, Bloatware Slayer only uses the built-in methods of Magisk and KernelSU/APatch to make the folders of pre-installed apps empty or invisible, preventing the system from installing and loading these apps. **The module itself does not directly modify the system. Once you disable or uninstall this module, all changes will be reverted**, and your system will not be damaged. This is the essence of being "systemless (no system modification)".

However, some apps should not be uninstalled or blocked casually. In the first place, **considering system stability, Some apps are essential for maintaining normal system operations**, such as Settings and System UI.

Fortunately, **only a small number of system apps fall into this category**. Perhaps only 20~30 out of 100 system apps.

Secondly, some manufacturers (e.g.MIUI, Huawei, Google) include a large number of apps that appear "reasonable" but are essentially adware and data collection tools.
These apps are placed on a system whitelist, and most restrictions do not apply to them. The critical issue is that **the system may refuse to boot if these apps are uninstalled or missing**.It may get stuck on the boot animation or refuse providing certain services.

If you add certain apps to `target.conf` and the device gets stuck on the boot animation or the first boot screen, it means either these apps are essential for maintaining normal system operations or they are the "uninstall-and-break" type of apps.In such cases, you need to use the brick recovery method. Here are some suggestions:

1. For **Magisk Alpha**, if the device fails to boot normally twice, it will enter safe mode and disable all modules on the third boot. You can then modify `target.conf`.
2. For **KernelSU/APatch**, during the boot process from the first screen to the boot animation, you can press the volume-down button about ten times consecutively (not long-press). If your device's KernelSU kernel includes the brick recovery code, it will likely enter safe mode and disable all modules.
3. For devices that support third-party Recovery, you can use the Recovery's module management interface to easily disable Bloatware Slayer when using Magisk.


#### Q: Bloatware Slayer会破坏我的设备吗？为什么需要救砖手段？

首先，Bloatware Slayer 只是使用了 Magisk 和 KernelSU/APatch 内置的办法，让这些预装 APP 的文件夹设置为空或者被屏蔽掉，从而使系统不再安装和加载这些软件。**模块本身并不会直接修改系统，一旦禁止或卸载本模块，所有的更改均会被还原**，你的系统也不会受到任何损害，正所谓`Systemless（不修改系统）`。
即使如此，有些 APP 不应该也不能被随意卸载或屏蔽。一来是考虑系统稳定性，**部分APP是必须存在才能维护系统正常的运行秩序的APP**——比如说设置和系统界面是在正常生产环境的设备中必须存在的 APP。
不过，**这类 APP 数量其实很稀少**，可能整整100个系统 APP 中只有20~30个 APP 属于这一类，大部分系统 APP 事实上并没有多重要，该动手就动手。
二来，某些品牌厂商（MIUI、Huawei、Google）为了持续收集用户信息，会在预装软件中安插一大批看起来 “十分合理” 但是细究起来就是广告毒瘤和信息收集的 APP (Google Play 服务、Google Assistant、应用商店、SystemHelper、AnalysisCore、Joyose)，**这些 APP 被放在系统内置的白名单内，大部分限制对它们而言无效，甚至一旦系统检测到它们被卸载或不存在，就直接拒绝开机或者拒绝提供某些服务。**
如果你将某些 APP 加入了 `target.conf` 但是卡在了开机动画甚至是开机第一屏，**要么这些APP是维持系统正常运行秩序所必须的 APP，要么这些APP就是所谓的“一卸载就罢工”的 APP**。
这个时候无论是排除法还是需要进入系统，就需要救砖手段了，以下是一些救砖建议：
1. 对于 Magisk Alpha，当设备两次无法正常进入系统时，在第三次启动就会自动进入安全模式，并禁用所有模块，此时你可以进入并修改 target.conf
2. 对于 KernelSU / APatch，在开机第一屏到开机动画期间可以连续按下音量减键十次左右（连续按，不是长按）,只要你的设备的 KernelSU 内核将救砖模式的代码编译在内，那么有大概率进入 KernelSU / APatch 的安全模式，所有模块会被禁用
3. 对于支持第三方 Recovery 的设备，当你使用 Magisk 时，你也可以直接使用这类 Recovery 的模块管理界面，轻松禁用 Bloatware Slayer。

## 经过测试的ROM
1. 小米澎湃系统2.0.105.0，安卓15，设备：红米 Note 9 Pro 5G 8+256GB (设备代号gauguin，移植系统)
- Root：Magisk Alpha 28102
2. 小米MIUI12.5.4，安卓10，设备：红米 Note 7 Pro 6+128GB (设备代号violet，原厂系统)
- Root：Magisk Alpha 28102
3. DroidUI-X，安卓14，设备：红米 Note 7 Pro 6+128GB (设备代号violet，类原生系统)
- Root: KernelSU with Magic Mount 1.0.3
- Root: KernelSU with OverlayFS 0.9.5
4. Flyme 8.0.5.0A, 安卓7.1.2, 设备: 魅蓝 Note 6 4+64GB (设备代号m1721, 原厂系统)
- Root: Magisk Lite 25205
5. Derpfest 15.1 Stable，安卓15，设备：红米 Note 7 Pro 6+128GB (设备代号violet，类原生系统)
- Root: Magisk Alpha 28103

## 帮助与支持
如果遇到问题，请点击 [此处](https://github.com/Astoritin/BloatwareSlayer/issues) 提交反馈
欢迎 [提交代码](https://github.com/Astoritin/BloatwareSlayer/pulls)，让该模块变得更好
