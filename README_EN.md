
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
