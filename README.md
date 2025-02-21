
# Bloatware Slayer / 干掉预装软件

A Magisk module to remove bloatware in systemlessly way / 一个无需修改 system 分区即可移除预装软件的 Magisk 模块

## Support Root Implements / 支持的 Root 方案

- [Magisk](https://github.com/topjohnwu/Magisk) (Recommended / 推荐!)
- [KernelSU](https://github.com/tiann/KernelSU) (Theoretically supported only / 仅理论上支持，未经实际测试)
- [APatch](https://github.com/bmax121/APatch) (Theoretically supported only / 仅理论上支持，未经实际测试)

## Details / 详细信息

This Magisk module deletes bloatware in Systemless way using Magisk's mount method and the node settings method of KernelSU and APatch. The general steps are listed below:
- Install Magisk / KernelSU / APatch.
- Download and install this module.
- Open /data/adb/bloatwareslayer/target.txt and add the folder names of the pre-installed apps you want to remove, one per line.
  For example, if I want to uninstall XiaoAI (the voice assistant), I would use AppManager to find that its folder name is VoiceAssistAndroidT.
  Then, I would copy VoiceAssistAndroidT into target.txt and press Enter.
  target.txt supports comments using the # symbol.
  Lines starting with # and empty lines will be ignored by the module.
  Save your changes to target.txt and reboot your device to see the effect.

该 Magisk 模块通过 Magisk 的挂载方式和 KernelSU 、 APatch 的节点设置办法，以 Systemless 方式删除预装软件
以下是大概的步骤：
- 安装 Magisk / KernelSU / APatch
- 下载并安装本模块
- 打开/data/adb/bloatwareslayer/target.txt，并将你通过各种方式获得的预装软件的App所在的文件夹名放在上面，一行一个
  例如：我需要卸载小爱同学，那么我会通过 AppManager 查看小爱同学所在的文件夹的名字是 VoiceAssistAndroidT
  然后将 VoiceAssistAndroidT 复制到target.txt并回车
  target.txt支持#号注释整行，模块不会处理被注释掉的行和空行
- 保存编辑target.txt并重新启动以查看效果

## Log / 查看日志

Log are saving in <code>/data/adb/bloatwareslayer/logs</code> , you can check it and give feedback if facing issues
日志被保存在 <code>/data/adb/bloatwareslayer/logs</code> , 你可以查看它并在反馈遇到的问题时提交该日志

## Tested ROMs / 经过测试的ROM
- Xiaomi HyperOS 2.0.105.0 Android 15 in Redmi Note 9 Pro 5G 8+256GB (gauguin,port ROM)
  小米澎湃系统2.0.105.0，安卓15，设备：红米 Note 9 Pro 5G 8+256GB (设备代号gauguin，移植系统)
- Xiaomi MIUI 12.5.4 Android 10 in Redmi Note 7 Pro 6+128GB (violet,stock ROM)
  小米MIUI12.5.4，安卓10，设备：红米 Note 7 Pro 6+128GB (设备代号violet，原厂系统)

## Help and Support / 帮助与支持

You can click [here](https://github.com/Astoritin/Bloatware_Slayer/issues) to give feedback if facing problems / 如果遇到问题，请点击 [此处](https://github.com/Astoritin/Bloatware_Slayer/issues) 提交反馈

[Pull request](https://github.com/Astoritin/Bloatware_Slayer/pulls) is always welcome to let this module become better / 欢迎 [pull request](https://github.com/Astoritin/Bloatware_Slayer/pulls)，让该模块变得更好
