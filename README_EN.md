[简体中文](README.md) 丨 English <br>

# Bloatware Slayer / 干掉预装软件

A Magisk module to remove bloatware in systemless way
/ 一个无需修改 system 分区即可移除预装软件的 Magisk 模块

<details open>
<summary>NOTICE</summary>
This Magisk required devices with unlocked BootLoader and specific Root Modules Manager (Magisk/KernelSU/APatch)
This Magisk module WILL NOT be able to work if your device doesn't get root access or even unlock BootLoader
</details>

## Support Root Implementation

- [Magisk](https://github.com/topjohnwu/Magisk) (Recommended!)
- [KernelSU](https://github.com/tiann/KernelSU) (Recommended!)
- [APatch](https://github.com/bmax121/APatch) (Theoretical support only, not tested yet)

## Details

This Magisk module deletes pre-installed bloatware in a Systemless manner through Magisk's mount method and specific mount methods for KernelSU and APatch. Here are the general steps for usage:

1. Install Magisk / KernelSU / APatch
2. Download and install this module
3. To obtain the directories/folders of the pre-installed bloatware, you need to do some preliminary research.<br>
For example, use App Manager or file explorers like Root Explorer and MiXplorer<br>
to manually locate and copy the folder names of the pre-installed apps in <code>/system</code>.<br>
4. Open <code>/data/adb/bloatwareslayer/target.txt</code> <br>
list the folder names of the pre-installed apps obtained in Step 3, **one per line**.<br>
5. Save the changes to target.txt, reboot your device, and check the results.<br>
You can see the number of apps blocked by the module (slain),<br>
the number of apps not found (missing)<br>
and the total number of apps targeted in the module description.<br>

For example, if I want to uninstall XiaoAI (the voice assistant), I would use AppManager to check the folder name of XiaoAI and find out that it is <code>VoiceAssistAndroidT</code>. I would then copy <code>VoiceAssistAndroidT</code> to <code>target.txt</code>, press Enter to save the changes, and reboot the device.

<details open>
<summary>NOTICE</summary>
<code>target.txt</code> supports commenting out entire lines with the "#" symbol.<br>
The module will ignore commented lines and blank lines.<br>
You can also specify custom paths, for example: <code>/system/app/MiVideo/</code>.<br>
In this case, Bloatware Slayer will directly handle the specified custom path without scanning other system folders.<br>
</details><br>

<details>
<summary>Q: Why do I need to manually copy the folder names instead of letting the module detect the system directories based on the app names or package names?</summary>

A:Firstly, <b>app names and package names are not reliable</b>.<br>
For most well-organized ROMs, system directories/folders are named in languages other than English is highly impossible.<br>
Moreover, there are many cases where the app name has no relation to its system directory/folder name at all.<br>
<em>For example, there is an app named "System Service", but its directory/folder name is "AdPushService", and its package name is "com.android.adpromote".</em><br>
As for package names, it is very difficult to locate the system directory of an app based on its package name during the post-fs-data stage.<br>By the time the system reaches the service stage or even can see the lockscreen, it is too late to detect the apps.<br>
At this point, the module system has already been mounted, and it is no longer possible to block system apps after this stage.<br><br>
Secondly, although this module operates in a Systemless way (without modifying the system),<br>
<b>you must always know and be certain of what you are doing</b>.<br>
You need to be aware of which system apps you want to block,<br>
<b>rather than blindly copying someone else's list and blaming the Magisk module when something goes wrong</b>.
</details>
