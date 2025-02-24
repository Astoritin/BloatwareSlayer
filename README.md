
# Bloatware Slayer / 干掉预装软件

A Magisk module to remove bloatware in systemlessly way
/ 一个无需修改 system 分区即可移除预装软件的 Magisk 模块

## Support Root Implements / 支持的 Root 方案

- [Magisk](https://github.com/topjohnwu/Magisk)
  (Recommended / 推荐!)
- [KernelSU](https://github.com/tiann/KernelSU)
  (Theoretically supported only / 仅理论上支持，未经实际测试)
- [APatch](https://github.com/bmax121/APatch)
  (Theoretically supported only / 仅理论上支持，未经实际测试)

## Details / 详细信息

This Magisk module deletes bloatware in Systemless way.
The general steps are listed below:
- Install Magisk / KernelSU / APatch
- Download and install this module
- Launch Text editor and open file
   <code>/data/adb/bloatwareslayer/target.txt</code>
  and add the folder names of the bloatware apps you want to remove,
 **one per line**.
  For example, if I want to uninstall XiaoAI (the voice assistant),
  I would use App Manager to find
that its folder name is <code>VoiceAssistAndroidT</code>.
  Then, I would copy VoiceAssistAndroidT into <code>target.txt</code>,
  press Enter and then save the change,
  reboot my device to see the effect.
  
  **target.txt supports comments using the <code>#</code> symbol.
  Lines starting with <code>#</code> and empty lines will be ignored by the module.**

该 Magisk 模块通过 Magisk 的挂载方式和 KernelSU 、 APatch 的节点设置办法，
以 Systemless 方式删除预装软件，以下是大概的步骤：
- 安装 Magisk / KernelSU / APatch
- 下载并安装本模块
- 打开/data/adb/bloatwareslayer/target.txt，
  并将你通过各种方式获得的预装软件的App所在的文件夹名放在上面，**一行一个**
  例如：我需要卸载小爱同学，那么我会通过 AppManager 查看小爱同学所在的文件夹
  得知其名字是 <code>VoiceAssistAndroidT</code>
  然后将 <code>VoiceAssistAndroidT</code> 复制到 <code>target.txt</code> ，
  回车并保存更改，重新启动以查看效果

  **target.txt支持#号注释整行，模块不会处理被注释掉的行和空行**

## Log / 查看日志

Log are saving in <code>/data/adb/bloatwareslayer/logs</code> , 
you can check it and give feedback if facing issues
日志被保存在 <code>/data/adb/bloatwareslayer/logs</code> ,
你可以查看它并在反馈遇到的问题时提交该日志

## Bootloop / 引导循环 (俗称变砖)

First, you need to understand that this module merely utilizes 
the built-in methods of Magisk and KernelSU/APatch 
to set the folders of these pre-installed apps as empty or to block them, 
thereby preventing the system from installing and loading these apps.
**The module itself does not directly modify the system**.
**Once this module is disabled or uninstalled, all changes will be reverted**,
and your system will be okay.
This is what we call <code>Systemless (no system modification)</code>.

Even so, some apps should not and cannot be uninstalled or blocked at will.
**For the sake of system stability**, certain apps should be left untouched.
However, most system apps are not that crucial,
so feel free to take action when necessary.

This mainly applies to <span title="MIUI">certain brand manufacturers</span>
that insert some "seemingly reasonable" apps to continuously collect user information.
These apps are placed on the system's built-in whitelist,
and most permission restrictions are ineffective against them.
**The most critical point is that if the system detects that these apps are uninstalled,**
**it will refuse to boot, getting stuck at the boot animation or denying certain services.**
**This is the truly annoying part.**
If you have added certain apps to <code>target.txt</code>
and your device gets stuck at the boot animation or even the splash screen,
it could be that **the system genuinely relies on these apps**,
or **these apps are the ones that trigger a frozen upon uninstallation**.

At this point, whether using the process of elimination or needing to access the system,
**unbrick measures are required**. Here are some suggestions:
- For Magisk Alpha, if the device **fails to boot normally twice**,
  **it will automatically enter Safe Mode and disable all modules on the third boot attempt**.
  You can then enter the system and modify the <code>target.txt</code>.

- For KernelSU / APatch, during the period from the splash screen to the boot animation,
  you can **press the volume-down button about ten times consecutively (not long press)**.
  If your device's KernelSU kernel has the unbrick code compiled in,
  there is a high probability that you will **enter the KernelSU / APatch Safe Mode**,
  **where all modules will be disabled**.

- For devices that **support third-party Recovery**, when using Magisk,
  you can **directly use the module management interface of such Recovery**
  to easily **disable Bloatware Slayer**.

- As for some "miracle" unbrick modules, they are worth a try,
  but the unbrick methods provided by the Root solution itself are more recommended.

首先，你需要知道的是，该模块只是使用了 Magisk 和 KernelSU/APatch 内置的办法
让这些预装 APP 的文件夹设置为空或者被屏蔽掉，
从而使系统不再安装和加载这些软件
**模块本身并不会直接参与修改系统**
**一旦禁止或卸载本模块，所有的更改均会被还原**，
你的系统也不会受到任何损害，
正所谓 <code>Systemless（不修改系统）</code>

即使如此，有些 APP 不应该也不能被随意卸载或屏蔽，
一来是为了**系统稳定性**（举个例子，设置和系统界面就属于此列）
不过除了特定的系统 APP 以外，大部分系统 APP 都没有那么重要就是了，该动手就动手。
二来，某些品牌厂商（MIUI）为了持续收集用户信息<br>会在预装软件中安插一大批<br>看起来 “十分合理” 但是细究起来<br>就是广告毒瘤和信息收集的 APP
(应用商店、SystemHelper、AnalysisCore、Joyose)
这些 APP 被放在系统内置的白名单内，
大部分权限限制对它们而言无效，
最关键的一点是，<br>**一旦系统检测到它们被卸载，就拒绝开机**<br>
一直停在开机动画界面或者拒绝提供某些服务，
这就是其恶心之处

如果你将某些 APP 加入了 <code>target.txt</code>
但是卡在了开机动画甚至是开机第一屏，
要么是**系统真的离不开这些 APP**，
要么是**这些 APP 就是所谓的一卸载就触发罢工的 APP**
这个时候无论是排除法还是需要进入系统，就需要**救砖手段**了
以下是一些救砖建议：

- 对于 **Magisk Alpha**，当设备**两次无法正常进入系统时**
  **在第三次启动就会自动进入安全模式，并禁用所有模块**，
  此时你可以进入并修改 target.txt
- 对于 **KernelSU / APatch**，在开机第一屏到开机动画期间
  可以**连续按下音量减键十次左右（连续按，不是长按）**
  只要你的设备的 KernelSU 内核将救砖模式的代码编译在内，
  那么有大概率进入 KernelSU / APatch 的安全模式，
  所有模块会被禁用
- 对于支持第三方 Recovery 的设备，当你使用 Magisk 时，
  你也可以**直接使用这类 Recovery 的模块管理界面，
  轻松禁用 Bloatware Slayer**
- 至于某些神仙救砖模块自不必多提，
  可以尝试，但是更推荐 Root 方案自带的救砖方法

## Tested ROMs / 经过测试的ROM
- Xiaomi HyperOS 2.0.105.0 Android 15
  in Redmi Note 9 Pro 5G 8+256GB (gauguin,port ROM)
- 小米澎湃系统2.0.105.0，安卓15，
  设备：红米 Note 9 Pro 5G 8+256GB (设备代号gauguin，移植系统)
- Xiaomi MIUI 12.5.4 Android 10
  in Redmi Note 7 Pro 6+128GB (violet,stock ROM)
- 小米MIUI12.5.4，安卓10，
  设备：红米 Note 7 Pro 6+128GB (设备代号violet，原厂系统)

## Help and Support / 帮助与支持

You can click [here](https://github.com/Astoritin/Bloatware_Slayer/issues) to give feedback if facing problems
/ 如果遇到问题，请点击 [此处](https://github.com/Astoritin/Bloatware_Slayer/issues) 提交反馈

[Pull request](https://github.com/Astoritin/Bloatware_Slayer/pulls) is always welcome to let this module become better
/ 欢迎 [pull request](https://github.com/Astoritin/Bloatware_Slayer/pulls)，让该模块变得更好
