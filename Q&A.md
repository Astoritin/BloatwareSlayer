English | [简体中文](Q&A_ZH-CN.md)

# **Bloatware Slayer / 干掉预装软件**
A Magisk module to remove bloatware in systemless way / 一个无需修改 system 分区即可移除预装软件的 Magisk 模块

# Question and Answer

## Q: Why do I need to manually copy the app dir names instead of letting the module detect the system directories based on the app names or package names?

### A: 1. **The APP name and package name are not reliable, and relying on these two factors to locate the APP folder is extremely inefficient.**
For most standardized ROMs, the probability of using languages other than English to name system directories/folders is extremely low.  
Moreover, there are quite a few APPs whose APP names have no relation to their system directory/folder names (whether due to the ROM provider's carelessness and lack of proficiency leading to non-standard naming details, or the sinister intentions of some apps that deliberately use non-standard naming to hide their user data collection activities). If one insists on matching them in this way, not only would a large amount of data analysis be required, but the error rate would still be quite high.  
> For example, there is an app named "System Service," but its directory/folder name is "AdPushService," and its package name is "com.android.adpromote."
### 2. **Regarding package names, this method will NOT be added is confirmed.** The reasons are as follows:
1) The feature requires adding an additional built-in component: aapt, which would increase the maintenance difficulty
2) Even with aapt added, while it might be okay for ROMs based on AOSP, for stock ROMs like HyperOS and MIUI, which have over 100 or even more than 200 system apps, scanning the package names of each APK individually would severely slow down the system boot speed and consume a large amount of resources
3) Moreover, if the package name can be obtained, it would naturally not be difficult to get the resource directory it is located in. Therefore, adding package name detection does not offer much convenience.
### 3. **Adding package directories manually is to make sure it is completely users' judgement and choice instead of rudeness behaviors without any thinking.**
Although this module operates in a Systemless (non-system-modifying) manner, **you must always know and be certain of what you are doing.** You need to know which system apps you have disabled, **instead of blindly copying someone else's list and then shifting all the blame to this Magisk module when problems arise.**

## Q: Will Bloatware Slayer damage my device? Why need to learn unbrick skills?

### A: 1. **The module itself does NOT directly modify the system. Once you disable or uninstall this module, all changes will be reverted** and your system will not be damaged. This is the essence of being "systemless (no system modification)".
Primarily, Bloatware Slayer only uses the built-in methods of Magisk and KernelSU/APatch to make the directories of pre-installed apps empty or invisible, preventing the system from installing and loading these apps.
### 2. However, some apps should not be uninstalled or blocked casually.
In the first place, **considering system stability, Some apps are essential for maintaining normal system operations**, such as Settings and System UI. Fortunately, **only a small number of system apps fall into this category**. Perhaps only 20~30 out of 100 system apps.
Secondly, some manufacturers (e.g.MIUI, Huawei, Google) include a large number of apps that appear "reasonable" but are essentially adware and data collection tools.
These apps are placed on a system whitelist, and most restrictions do not apply to them. The critical issue is that **the system may refuse to boot if these apps are uninstalled or missing**.It may get stuck on the boot animation or refuse providing certain services.
### 3. If you add certain apps to `target.conf` and the device gets stuck on the boot animation or the first boot screen, it means either these apps are essential for maintaining normal system operations or they are the "uninstall-and-break" type of apps.
In such cases, you need to use the brick recovery method. Here are some suggestions:
1. For **Magisk Alpha**, if the device fails to boot normally twice, it will enter safe mode and disable all modules on the third boot. You can then modify `target.conf`.
2. For **KernelSU/APatch**, during the boot process from the first screen to the boot animation, you can press the volume-down button about ten times consecutively (not long-press). If your device's KernelSU kernel includes the brick recovery code, it will likely enter safe mode and disable all modules.
3. For devices that support third-party Recovery, you can use the Recovery's module management interface to easily disable Bloatware Slayer when using Magisk.

## Q: I have seen there is WebUI components in your source code, why there is NOT inbuilt yet in release versions?

### A: Note on WebUI Support: Not considered for now. The reasons are as follows: 1. I don't need it personally, while the effort-to-reward ratio is NOT fair.
Bloatware Slayer is a self-use module, as my main devices use Magisk Alpha. I have little chance to use WebUI unless I use the KsuWebUI APP, and I can't accept maintaining a feature I won't use.
### 2. The module would become too bloated. WebUI is currently just a showy feature. It would be ironic if Bloatware Slayer became like bloatware.
The original Magisk module size was moderate (20KB). Adding WebUI requires importing resources for offline use, making the zip file 116KB. It would be even larger when unzipped.
### 3. WebUI brings more issues.
Bloatware Slayer's config files are in `/data/adb/bloatwareslayer/` to avoid easy detection. Normal apps can't access this directory without Root and SELinux permissive mode, even the front-end native APIs. Using KernelSU's API (ksu.exec) brings convenience, but also security risks and maintenance challenges. Bloatware Slayer is unstable still, I don't want to open another potential maintenance entry and I feel so sorry for any inconvenience.
