[简体中文](README.md) 丨 English <br>

# Bloatware Slayer / 干掉预装软件

A Magisk module to remove bloatware in systemless way
/ 一个无需修改 system 分区即可移除预装软件的 Magisk 模块

<details open>
<summary>NOTICE</summary>
This Magisk required devices with unlocked BootLoader and specific Root Modules Manager (Magisk/KernelSU/APatch).
This Magisk module WILL NOT be able to work if your device doesn't get root access or even unlock BootLoader.
</details>

## Support Root Implementation

- [Magisk](https://github.com/topjohnwu/Magisk) (Recommended!)
- [KernelSU](https://github.com/tiann/KernelSU) (Recommended!)
- [APatch](https://github.com/bmax121/APatch) (Theoretical support only, not tested yet)

## Details

This Magisk module deletes pre-installed bloatware in a Systemless manner through Magisk's mount method and specific mount methods for KernelSU and APatch. Here are the general steps for usage:

1. Install Magisk / KernelSU / APatch.
2. Download and install this module.
3. To obtain the directories/folders of the pre-installed bloatware, you need to do some preliminary research.<br>
For example, use App Manager or file explorers like Root Explorer and MiXplorer<br>
to manually locate and copy the folder names of the pre-installed apps in <code>/system</code>.<br>
4. Open <code>/data/adb/bloatwareslayer/target.txt</code> <br>
list the folder names of the pre-installed apps obtained in Step 3, **one per line**.<br>
5. Save the changes to target.txt, reboot your device, and check the results.<br>
You can see the number of apps blocked by the module (slain),<br>
the number of apps not found (missing)<br>
and the total number of apps targeted in the module description.<br>

For example, if I want to uninstall XiaoAI (the voice assistant), I would use AppManager to check the folder name of XiaoAI and find out that it is <code>VoiceAssistAndroidT</code>. I would then copy <code>VoiceAssistAndroidT</code> to <code>target.txt</code>, press Enter to save the changes, and reboot the device.<br>

<details open>
<summary>NOTICE</summary>
<ol>
<li><code>target.txt</code> supports commenting out entire lines with the "#" symbol.<br>
Bloatware Slayer will ignore commented lines and empty lines.</li><br>
<li>You can also order custom paths, for example: <code>/system/app/MiVideo/</code>.</li><br>
In this case, Bloatware Slayer will directly process the custom path without scanning other system folders.<br><br>
<li>Since most modern devices use SAR (System-as-root), the resource directory names you see in AppManager may not start with <code>/system</code> (for example,<code>/product/app/Scanner</code>).<br>
To ensure the mount works, manually add <code>/system</code> to the beginning of paths. Otherwise, Bloatware Slayer will ignore them.</li><br>
<li>If the resource directory starts with <code>/data</code>, it means the app was installed as first booting after the initial of ROM setup.<br>
You can uninstall it manually and should not add it to <code>target.txt</code>, as Bloatware Slayer's processing will not affect such apps.</li><br>
</ol>
</details><br>

<details>
<summary>Q: Why do I need to manually copy the folder names instead of letting the module detect the system directories based on the app names or package names?</summary>

A:Firstly, <b>app names and package names are not reliable</b>.<br>
For most standard ROMs, system directories/folders are named in languages other than English is highly impossible.<br>
Moreover, there are many cases where the app name has no relation to its system directory/folder name at all.<br>
<em>For example, there is an app named "System Service", but its directory/folder name is "AdPushService", and its package name is "com.android.adpromote".</em><br>
As for package names, it is very difficult to locate the system directory of an app based on its package name during the post-fs-data stage.<br>By the time the system reaches the service stage or even can see the lockscreen, it is too late to detect the apps.<br>
At this point, the module system has already been mounted, and it is no longer possible to block system apps after this stage.<br><br>
Secondly, although this module operates in a Systemless way (without modifying the system),<br>
<b>you must always know and be certain of what you are doing</b>.<br>
You need to be aware of which system apps you want to block,<br>
<b>rather than blindly copying someone else's list and blaming the Magisk module when something goes wrong</b>.<br>
</details><br>

## Logs

Logs are saved in <code>/data/adb/bloatwareslayer/logs</code>. You can review them and submit them when reporting issues.

<details open>
<summary>Notice</summary>
<code>log_pfd_(timestamp).txt</code> contains logs related to the core functionality of Bloatware Slayer.<br>
Since the system is not fully initialized at this stage, the timestamps may appear unusual. Please do not be concerned.<br>
<code>log_s_(timestamp).txt</code> contains logs related to additional features of Bloatware Slayer.<br>
<code>log_install_(timestamp).txt</code> is the log automatically generated during the installation of Bloatware Slayer.<br>
When reporting issues, please package the entire logs folder and upload it.
</details>


## UnBrick

Bloatware Slayer has a built-in brick recovery mechanism. If the device takes too long to boot, it will automatically disable the module's mounting functionality and reboot.<br>
After rebooting, you will see a message in the module status.<br>
Please adjust <code>target.txt</code> by removing entries that should not be disabled and reboot again.<br><br>
The default wait time is 300 seconds (5 minutes), meaning Bloatware Slayer will disable itself and reboot after waiting for 5 minutes.<br>If your system is updating, temporarily disable or uninstall this module and reinstall it later is recommended.

<details>
<summary>Q: Will Bloatware Slayer damage my device? Why need to learn unbrick skills?</summary>
Firstly, Bloatware Slayer only uses the built-in methods of Magisk and KernelSU/APatch to make the folders of pre-installed apps empty or invisible, preventing the system from installing and loading these apps.<br>
<b>The module itself does not directly modify the system</b>.<br>
Once you disable or uninstall this module, all changes will be reverted, and your system will not be damaged.<br>
This is the essence of being "systemless (no system modification)"<br><br>
However, some apps should not be uninstalled or blocked casually.<br>
Firstly, consider <b>system stability</b>.<br>
<b>Some apps are essential for maintaining normal system operations</b>, such as Settings and System UI.<br>
Fortunately, only a small number of system apps fall into this category----perhaps only 20-30 out of 100 system apps.<br><br>
Secondly, some manufacturers (e.g.MIUI, Huawei, Google) include a large number of apps that appear "reasonable" but are essentially adware and data collection tools.<br>
These apps are placed on a system whitelist, and most restrictions do not apply to them. The critical issue is that <b>the system may refuse to boot if these apps are uninstalled or missing</b>.<br>It may get stuck on the boot animation or fail to provide certain services.<br><br>
If you add certain apps to <code>target.txt</code> and the device gets stuck on the boot animation or the first boot screen, it means either these apps are essential for maintaining normal system operations or they are the "uninstall-and-break" type of apps.<br>In such cases, you need to use the brick recovery method. Here are some suggestions:<br>

1. For **Magisk Alpha**, if the device fails to boot normally twice, it will enter safe mode and disable all modules on the third boot. You can then modify <code>target.txt</code>.
2. For **KernelSU/APatch**, during the boot process from the first screen to the boot animation, you can press the volume-down button about ten times consecutively (not long-press). If your device's KernelSU kernel includes the brick recovery code, it will likely enter safe mode and disable all modules.
3. For devices that support third-party Recovery, you can use the Recovery's module management interface to easily disable Bloatware Slayer when using Magisk.
</details>

## Tested ROMs

1. Xiaomi HyperOS 2.0.105.0, Android 15, Device: Redmi Note 9 Pro 5G 8+256GB (gauguin, ported ROM)<br>
    Root: Magisk Alpha 28102<br>
2. Xiaomi MIUI 12.5.4, Android 10, Device: Redmi Note 7 Pro 6+128GB (violet, stock ROM)<br>
    Root: Magisk Alpha 28102<br>

## Help and Support

If you encounter any problems, please [click here](https://github.com/Astoritin/Bloatware_Slayer/issues) to submit feedback.<br>
[Pull Request](https://github.com/Astoritin/Bloatware_Slayer/pulls) is always welcome to improve this module.
