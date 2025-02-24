# Bloatware Slayer / 干掉预装软件
A Magisk module to remove bloatware in systemlessly way / 一个无需修改 system 分区即可移除预装软件的 Magisk 模块

## Changelog / 变更日志

### 1.0.5
- Support KernelSU officially
- 正式支持 KernelSU
- Change the mount method for KernelSU and APatch from mknod to mount directly
- 更改 KernelSU 和 APatch 的挂载方法，从 mknod 改为直接挂载
- Rewrite enforce_install_from_magisk_app function
- 重写 enforce_install_from_magisk_app() 函数
- Simplify certain processes to match the changes in aautilities.sh
- 简化部分流程以匹配 aautilities.sh 的更改

### 1.0.3
- Add simple inbuilt unbrick method
  新增简易的内置救砖方法
  Bloatware Slayer will reboot and skip mounting this module next time  
  if booting fails in **300** seconds.  
  Please check target list in <code>/data/adb/bloatwareslayer/target.txt</code>  
  and delete the items may caused brick.
  现在如果系统在**300秒**后仍未完成启动，  
  模块会自行重新启动并在下次启动时跳过挂载该模块  
  请检查<code>/data/adb/bloatwareslayer/target.txt</code>的列表
  并删除可能会导致变砖的项目  

- Optimize logic for some code
  优化部分逻辑
- Improve the module status prompt content
  优化模块状态提示内容

### 1.0.2
- Optimize the judgment logic to reduce bugs caused by some extreme cases.
  优化判断逻辑，减少部分极端情况导致的bug
- Improve the module status prompt content
  优化模块状态提示内容

### 1.0.0
- Initial build / the first page
  第一页
