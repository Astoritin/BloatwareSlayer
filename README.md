
# 干掉预装软件 / Bloatware Slayer

一个无需修改 system 分区即可移除预装软件的 Magisk 模块
/ A Magisk module to remove bloatware in systemlessly way

<details open>
<summary>注意</summary>
该 Magisk 模块仅能在已解锁 Bootloader 的设备上使用，并且需要特定的 Root 模块管理器 (Magisk、KernelSU、APatch)。
如果你没有 Root 甚至没有解锁 Bootloader，那么该 Magisk 模块无法在你的设备上工作。
</details>

## 支持的 Root 方案

- [Magisk](https://github.com/topjohnwu/Magisk) (推荐!)
- [KernelSU](https://github.com/tiann/KernelSU) (推荐!)
- [APatch](https://github.com/bmax121/APatch) (仅理论上支持，未经实际测试)

## 详细信息

该 Magisk 模块通过 Magisk 的挂载方式和用于 KernelSU 和 APatch 的特定挂载方法，
以 Systemless 的方式删除预装软件，以下是大概的使用步骤：

1. 安装 Magisk / KernelSU / APatch
2. 下载并安装本模块
3. 为了获得预装软件所在的目录/文件夹，你需要提前做好功课，
例如使用 [App Manager](https://github.com/MuntashirAkon/AppManager)
或使用Root Explorer、MiXplorer 在 <code>/system</code> 处
手动寻找并复制预装软件的文件夹名<br>
4. 打开 <code>/data/adb/bloatwareslayer/target.txt</code>，<br>
并将你通过步骤3获得的预装软件所在的文件夹名放在上面，**一行一个**<br>
5. 保存 target.txt 的更改，并重新启动后查看效果，
你可以在模块描述里看到被该模块屏蔽的APP数 (slain)<br>
未找到目录的APP数 (missing)<br>
列表里配置的APP总数 (targeted in total)<br>

例如：我需要卸载小爱同学，那么我会通过 AppManager 查看小爱同学所在的文件夹，得知其名字是 <code>VoiceAssistAndroidT</code>，
然后将 <code>VoiceAssistAndroidT</code> 复制到 <code>target.txt</code> ，回车并保存更改后重启设备。<br>

<details open>
<summary>注意</summary>
target.txt支持#号注释整行，模块不会处理被注释掉的行和空行。<br>
你也可以自定义路径，例如：<code>/system/app/MiVideo/</code>。<br>
此时 Bloatware Slayer 会直接处理该自定义路径而不会再扫描其他系统文件夹。
</details><br><br><br>

<details>
<summary>Q: 为什么需要我手工复制，而不是模块根据我指定的应用名称或包名自行检测？</summary>

A: 其一，**应用名称和包名并不可靠。** <br>
对于大多数规范的ROM而言，用除了英文以外的其他语言给系统目录/文件夹命名的概率极低，<br>
甚至有不少应用的应用名称跟其所在的系统目录/文件夹名没有任何关系。<br><br>
<em>举个例子：有个APP名为系统服务，但是其目录/文件夹名为AdPushService，其包名为com.android.adpromote</em><br>
至于包名，在post-fs-data阶段很难做到根据包名查应用程序所在的系统目录，而一旦进入service阶段，甚至是进入系统桌面阶段再查就没有意义了。<br>
因为此时模块系统已完成挂载，无法再屏蔽系统应用了。<br>

其二，虽然该模块是在 Systemless (不修改系统) 的情况下运行，但是**你始终需要知道并确定自己正在做的事情**，你必须知道自己需要屏蔽掉哪些系统 APP，<br>**而不是照搬别人的列表，出问题了就把责任全部推给本 Magisk 模块**。
</details>

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
