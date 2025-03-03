简体中文 丨 [English](README_EN.md) <br>

# 干掉预装软件 / Bloatware Slayer

一个无需修改 system 分区即可移除预装软件的 Magisk 模块
/ A Magisk module to remove bloatware in systemlessly way

<details>
<summary>注意</summary>
该 Magisk 模块仅能在已解锁 Bootloader 的设备上使用，并且需要特定的 Root 模块管理器 (Magisk、KernelSU、APatch)。
如果你没有 Root 甚至没有解锁 Bootloader，那么该 Magisk 模块无法在你的设备上工作。
</details>

## 支持的 Root 方案

- [Magisk](https://github.com/topjohnwu/Magisk) (推荐!)
- [KernelSU](https://github.com/tiann/KernelSU) (推荐!)
- [APatch](https://github.com/bmax121/APatch) (仅理论上支持，未经实际测试)

## 详细信息

该 Magisk 模块通过 Magisk、KernelSU 和 APatch 的特定挂载方法，
以 Systemless 的方式删除预装软件，以下是大概的使用步骤：

1. 安装 Magisk / KernelSU / APatch
2. 下载并安装本模块
3. 为了获得预装软件所在的目录/文件夹，你需要提前做好功课<br>
例如使用 [App Manager](https://github.com/MuntashirAkon/AppManager)<br>
或使用Root Explorer、MiXplorer在 <code>/system</code> 处手动寻找并复制预装软件的文件夹名<br>
4. 打开 <code>/data/adb/bloatwareslayer/target.txt</code>，<br>
并将你通过步骤3获得的预装软件所在的文件夹名放在上面，**一行一个**<br>
5. 保存 target.txt 的更改，并重新启动后查看效果<br><br>

你可以在模块描述里看到被该模块屏蔽的APP数 (slain)<br>
未找到目录的APP数 (missing)<br>
列表里配置的APP总数 (targeted in total)<br>

例如：我需要卸载小爱同学，那么我会通过 AppManager 查看小爱同学所在的文件夹，得知其名字是 <code>VoiceAssistAndroidT</code>，
然后将 <code>VoiceAssistAndroidT</code> 复制到 <code>target.txt</code> ，回车并保存更改后重启设备。<br>

<details open>
<summary>注意</summary>
<ol>
<li><code>target.txt</code> 支持"#"号注释整行，Bloatware Slayer 不会处理被注释掉的行和空行。</li><br>
<li>你也可以自定义路径，例如：<code>/system/app/MiVideo/</code>。</li><br>
此时 Bloatware Slayer 会直接处理该自定义路径而不会再扫描其他系统文件夹。<br><br>
<li>由于现如今绝大多数设备都是 SAR (System-as-root)，你可能在 AppManager 中看到的资源目录名不是 <code>/system</code> 开头 (例如  <code>/product/app/Scanner</code>)，为了确保挂载生效，请手动在这类路径前面添加 <code>/system</code> ，否则 Bloatware Slayer 会直接忽略该路径</li><br>
<li>若你看到的资源目录以 <code>/data</code> 开头，则说明该APP是安装完ROM后的第一次初始化安装上的，实质上属于用户应用，只是内置于ROM的刷机包的特定目录，不属于目前 Root 方案能直接干涉的范畴。这类应用可以自行卸载，并且只有恢复出厂设置时才可能重新被自动安装，请不要加入到 <code>target.txt</code> 中，因为Bloatware Slayer的处理也不会对这类软件生效</li><br>
</ol>
</details><br>

<details>
<summary>Q: 为什么需要我手工复制，而不是模块根据我指定的应用名称或包名自行检测？</summary>

**其一，应用名称和包名并不可靠，依靠这两点查找应用文件夹的效率太低了**。<br>
对于大多数规范的ROM而言，用除了英文以外的其他语言给系统目录/文件夹命名的概率极低，<br>
甚至有不少应用的应用名称跟其所在的系统目录/文件夹名没有任何关系（无论是ROM提供商的疏忽和学艺不精导致的命名细节不规范，还是为了隐藏自己收集用户信息安插的眼线APP的阴暗心思而故意不规范命名）。如果一定要这么匹配，且不说需要大量的数据统计，即使如此，误判率也还是很高。<br><br>
<em>举个例子：有个APP名为系统服务，但是其目录/文件夹名为AdPushService，其包名为com.android.adpromote</em><br><br>
至于包名，请阅读 [【已确认不会添加的功能：检测包名 / Detecting packages name is permanently off the table】](https://github.com/Astoritin/Bloatware_Slayer/issues/6#issuecomment-2693035556)。
<br>

其二，虽然该模块是在 Systemless (不修改系统) 的情况下运行，但是**你始终需要知道并确定自己正在做的事情**，你必须知道自己需要屏蔽掉哪些系统 APP，**而不是照搬别人的列表，出问题了就把责任全部推给本 Magisk 模块**。
</details><br>

## 日志

日志被保存在 <code>/data/adb/bloatwareslayer/logs</code> ,
你可以查看它并在反馈遇到的问题时提交该日志<br>
<details>
<summary>注意</summary>
log_pfd_(时间戳).txt 是Bloatware Slayer v1.0.9- 的核心功能相关的日志，由于此阶段系统尚未初始化完毕，你看到的日期可能会非常离谱，请不要介意。由于post-fs-data.sh已于 v1.1.0+ 移除，你不应该在反馈问题时提交该日志。<br>
log_s_(时间戳).txt 是Bloatware Slayer v1.0.9- 附加功能相关的日志，v1.1.0+ 的核心功能的日志，时间戳已经正常初始化。<br>
反馈问题时，请直接打包整个logs文件夹后上传。<br>
</details>

## 救砖

Bloatware Slayer 内置救砖机制，当检测到手机启动时间过长，会自动禁用模块的挂载功能并自动重启<br>
重启后，你会在模块状态上看见相应信息，请自行调整 <code>target.txt</code> ，删除不该被禁用的项目后重新启动<br>
默认的等待时长是300秒（5分钟），也就是说 Bloatware Slayer 会在等待5分钟后自我禁用并重新启动。
若你的系统正在更新，请临时彻底禁用或卸载该模块，之后再安装。

<details>
<summary>Q: Bloatware Slayer会破坏我的设备吗？为什么需要救砖手段？</summary>
首先，Bloatware Slayer 只是使用了 Magisk 和 KernelSU/APatch 内置的办法，<br>
让这些预装 APP 的文件夹设置为空或者被屏蔽掉，从而使系统不再安装和加载这些软件。<br>
<b>模块本身并不会直接参与修改系统</b><br>
<b>一旦禁止或卸载本模块，所有的更改均会被还原</b><br>
你的系统也不会受到任何损害，正所谓<code>Systemless（不修改系统）</code><br>

即使如此，有些 APP 不应该也不能被随意卸载或屏蔽。
一来是考虑<b>系统稳定性</b>，部分 APP 是必须存在才能维护系统正常的运行秩序的程序，<br>
比如说设置和系统界面是在正常生产环境的设备中必须存在的 APP。<br>
不过，<b>这类 APP 数量其实很稀少</b>，可能整整100个系统 APP 中只有20~30个 APP 属于这一类，<br>
大部分系统 APP 事实上并没有多重要，该动手就动手。<br><br>
二来，某些品牌厂商（MIUI、Huawei、Google）为了持续收集用户信息<br>
会在预装软件中安插一大批看起来 “十分合理” 但是细究起来就是广告毒瘤和信息收集的 APP<br>
(Google Play 服务、Google Assistant、应用商店、SystemHelper、AnalysisCore、Joyose)<br>
这些 APP 被放在系统内置的白名单内，大部分限制对它们而言无效，
最关键的一点是，<br><b>一旦系统检测到它们被卸载或不存在，就直接拒绝开机</b><br>
一直停在开机动画界面或者拒绝提供某些服务。<br><br>
如果你将某些 APP 加入了 <code>target.txt</code> 但是卡在了开机动画甚至是开机第一屏，<br>
要么这些 APP 是<b>维持系统正常运行秩序所必须的 APP</b>，<br>
要么是<b>这些 APP 就是所谓的“一卸载就罢工”的 APP</b><br>
这个时候无论是排除法还是需要进入系统，就需要<b>救砖手段</b>了，以下是一些救砖建议：<br>

1. 对于 <b>Magisk Alpha</b>，当设备<b>两次无法正常进入系统时</b>，<b>在第三次启动就会自动进入安全模式，并禁用所有模块</b>，此时你可以进入并修改 target.txt<br>
2. 对于 <b>KernelSU / APatch</b>，在开机第一屏到开机动画期间可以<b>连续按下音量减键十次左右（连续按，不是长按）</b>,<br>
  只要你的设备的 KernelSU 内核将救砖模式的代码编译在内，那么有大概率进入 KernelSU / APatch 的安全模式，所有模块会被禁用<br>
3. 对于支持第三方 Recovery 的设备，当你使用 Magisk 时，你也可以<b>直接使用这类 Recovery 的模块管理界面，轻松禁用 Bloatware Slayer</b><br>
</details>

## 经过测试的ROM
1. 小米澎湃系统2.0.105.0，安卓15，设备：红米 Note 9 Pro 5G 8+256GB (设备代号gauguin，移植系统)<br>
    Root：Magisk Alpha 28102
2. 小米MIUI12.5.4，安卓10，设备：红米 Note 7 Pro 6+128GB (设备代号violet，原厂系统)
    Root：Magisk Alpha 28102

## 帮助与支持

如果遇到问题，请点击 [此处](https://github.com/Astoritin/Bloatware_Slayer/issues) 提交反馈

欢迎 [Pull request](https://github.com/Astoritin/Bloatware_Slayer/pulls)，让该模块变得更好
