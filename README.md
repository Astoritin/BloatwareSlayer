English | [简体中文](README_ZH-CN.md)

# **Bloatware Slayer / 干掉预装软件**
A Magisk module to remove bloatware systemlessly / 一个无需修改 system 分区即可移除预装软件的 Magisk 模块

## Supported Root Solution
[Magisk](https://github.com/topjohnwu/Magisk) (Recommended!) 丨 [KernelSU](https://github.com/tiann/KernelSU) (Recommended!) 丨 [APatch](https://github.com/bmax121/APatch) (Not test yet)

## Steps
Bloatware Slayer removes bloatwares systemlessly, using specific mount methods from Magisk, KernelSU and APatch. Below are the steps:
1. Install Magisk / KernelSU / APatch
2. Download and install Bloatware Slayer
3. Use [App Manager](https://github.com/MuntashirAkon/AppManager) to search for the system app names you want to block, open the app details page and copy source directory. Root Explorer, MiXplorer to manually locate and copy the directory names of pre-installed apps under `/system` is okay too.
4. Open the file `/data/adb/bloatwareslayer/target.conf` and add the directories of the bloatwares obtained in step 3, **one per line**.
5. Save the changes to `target.conf` and reboot your device to observe the results.
> For example, I need to uninstall XiaoAi Voice Assistant, so I will get the directory XiaoAi Voice Assistant located in by AppManager and soon get its name `VoiceAssistAndroidT`, then copy `VoiceAssistAndroidT` and add it into `target.conf` , save the changes and reboot my device.

## NOTICE
1. `target.conf` supports commenting out entire lines with the "#" symbol. Bloatware Slayer will ignore commented lines and empty lines.
2. Bloatware Slayer supports custom paths, for example: `/system/app/MiVideo`. In this case, Bloatware Slayer will directly process the custom path without scanning other system directories.
3. ~~Since most modern devices use SAR (System-as-root), the resource directory names you see in AppManager may not start with `/system` (for example, `/product/app/Scanner`). To ensure the mount works, you need to add `/system` manually to the beginning of paths. Otherwise, Bloatware Slayer will ignore them.~~
> Bloatware Slayer supports adding `/system` to the APP path directly since `1.4.1`, adding `/system` prefix manually is not enforced anymore.
> If item `/system` exists in `target.conf`, this item will be ignored.
4. To save the time and reduce the cost of resources, now Bloatware Slayer will update the items of `target.conf` into the system path bloatwares located in automatically in each time booting. You can read the chapter `Config File` to know.
5. If the resource directory starts with `/data`, it means the app was installed as first booting after the initial of ROM setup. You can uninstall it manually and should NOT add it to `target.conf`, as Bloatware Slayer's processing will not affect such apps.

## Configuration File
Starting from version v1.2.1, Bloatware Slayer supports manually enabling or disabling the following features. Please open the configuration file `/data/adb/bloatwareslayer/settings.conf` to view and modify the settings if needed.

1. **`brick_rescue`**: To set if module inbuilt brick rescue mode has enabled. The default value is `true`.
> If setting `brick_rescue=false`, Bloatware Slayer will do NOTHING if detecting device cannot boot.
2. **`brick_timeout`**: Sets the timeout for determining if the device has bricked. It requires a positive integer, measured in seconds.
> If it is not set in `settings.conf`, the default value is `300 seconds (5 minutes)`.
3. **`disable_module_as_brick`**: Determines whether the module should automatically disable itself when the device is detected as bricked. By default, it is set to `true` (enabled), but you can set it to `false` to disable this feature.
> When enabled, the module will disable itself to prevent further issues. If you set it to `false`, the module will only skip mounting without disabling itself. This allows you to troubleshoot and reboot the system after removing unstable items from `target.conf`, without needing to re-enable the module via Root manager manually.
4. **`last_worked_target_list`**: The worked target list at the last time feature. Bloatware Slayer will backup the latest `target.conf` can boot successfully, and restore it and reboot again as detecting device cannot boot. It is set to `true` (enable).
> This options cannot work with `disable_module_as_brick` enabled. That means if enable `disable_module_as_brick`, the option `last_worked_target_list` will NOT take effect logically.
5. **`slay_mode`**: the method of Bloatware Slayer blocking bloatwares.
- `MB` (Mount Bind), a method that is generally applicable to various Root solutions in most ROMs.  
- `MR` (Magisk Replace), a method specific to Magisk.  
- `MN` (Make Node), a method available for Magisk 28102+、KernelSU, and APatch.
In `settings.conf`, the default value of Bloatware Slayer is `MB` (Mount Bind), since the method has the highest compatibility.
6. **`mb_umount_bind`**: As `slay_mode` setting to `MB` (Mount Bind) and this option is enabled, Bloatware Slayer will unmount the mount points created by itself and hide the traces by module itself. It is set to `true`(enable) by default.
> You do NOT need to change this option usually.
7. **`system_app_paths`**: Support customizing the scan of system directories the bloatware located in. Paths starts with `/` and separated by spaces.
> For example: `system_app_paths=/system/app /system/priv-app`.
8. **`auto_update_target_list`**: Control the behavior whether to update the items in `target.conf` to the paths of bloatwares apps during each boot. By default, it is set to `true` (enabled) to speed up system boot.
> If you prefer to keep your custom comments or retain items in `target.conf` that were not found by the module, you can set this to `false`.
9. **`update_desc_on_action`**: Updates the module status description with denylist enforcing status of Magisk and Zygisk Next, and the status when the module is disabled or uninstalled. It is set to `true`(enable) by default.

## Frequently Asked Questions
Please read [Q&A](Q&A.md).

## Logs
Logs are saved in `/data/adb/bloatwareslayer/logs`, you can review them and submit them when reporting issues. 

**When reporting issues, please simply zip the entire logs folder and upload it.**

## Unbrick
Bloatware Slayer has a built-in brick recovery method. If the device takes too long to boot, it will automatically disable the module's mounting functionality and reboot.
After rebooting, you will see a message in the module status.
Please adjust `target.conf` by removing entries that should not be disabled and reboot again.
The default wait time is 300 seconds (5 minutes), meaning Bloatware Slayer will disable itself and reboot after waiting for 5 minutes.If your system is updating, temporarily disable or uninstall this module and reinstall it later is recommended.

## Tested ROMs
1. Xiaomi HyperOS 2.0.105.0, Android 15, Device: Redmi Note 9 Pro 5G 8+256GB (gauguin, ported ROM)
- Root: Magisk Alpha 28102,28103,28104,29001
2. Xiaomi MIUI 12.5.4, Android 10, Device: Redmi Note 7 Pro 6+128GB (violet, stock ROM)
- Root: Magisk Alpha 28102,28103,29001
3. DroidUI-X，Android 14，Device：Redmi Note 7 Pro 6+128GB (violet，AOSP based ROM)
- Root: KernelSU with Magic Mount 1.0.3
- Root: KernelSU with OverlayFS 0.9.5
4. Flyme 8.0.5.0A, Android 7.1.2, Device: Meizu M6 Note 4+64GB (m1721, stock ROM)
- Root: Magisk Lite 25205
5. Derpfest 15.1 Stable, Android 15, Device: Redmi Note 7 Pro 6+128GB (violet, AOSP based ROM)
- Root: Magisk Alpha 28103,28104,29001

## Help and Support
- If you encounter any problems, please [click here](https://github.com/Astoritin/BloatwareSlayer/issues) to submit feedback.
- [Pull Request](https://github.com/Astoritin/BloatwareSlayer/pulls) is always welcome to improve this module.

## Credits
- [Magisk](https://github.com/topjohnwu/Magisk) - the foundation which makes everything possible
- [Zygisk Next](https://github.com/Dr-TSNG/ZygiskNext) - the implementation of function extract and root solution check
- [LSPosed](https://github.com/LSPosed/LSPosed) - the implementation of function extract and root solution check
