# Bloatware Slayer / 干掉预装软件
A Magisk module to remove bloatware in systemlessly way / 一个无需修改 system 分区即可移除预装软件的 Magisk 模块

## Changelog / 变更日志

## 1.0.9

- 现在的模块描述中，移除的显示优先级比禁用高
- Now the priority of status remove showing in module description is higher than disable
- 降低模块描述刷新频率至3秒以减少CPU开销
- Reduce module description refresh rate to 3 seconds to decrease CPU overhead
- 不再自动生成安装日志，请手动从 Magisk / KernelSU 处导出
- No more install log automatically, please export it from Magisk / KernelSU manually
- 优化日志输出，移除部分不必要的代码
- Optimize log output and remove some unnecessary code

## 1.0.8

- 现在，当<code>/data/adb/bloatwareslayer/logs</code>下的日志过多，Bloatware Slayer会在安装或更新过程中清除较早的日志
- Bloatware Slayer will clean old logs in updating or installing if there are too many files under the folder <code>/data/adb/bloatwareslayer/logs</code>
- 新增扫描的系统预装软件目录：<br><code>/system/vendor/app</code><br><code>/system/vendor/priv-app</code><br>
- Add new system pre-install directories: <br><code>/system/vendor/app</code><br><code>/system/vendor/priv-app</code><br>

### 1.0.7

- Support custom directory (add "/system/(custom dir name)/(custom dir name)" to target.txt)
- 支持自定义目录 (添加 "/system/(自定义目录名称)/(自定义目录名称)" 至target.txt)
- Now, you can order the dirs of bloatware you want to block manually
- 现在，你可以手动设定你想要阻止的预装软件所在路径 
- Now Bloatware Slayer will ignore space/blank before the text per line
- 现在，Bloatware Slayer 会无视每行文本前的空格
- Bloatware Slayer will correct the wrong symbol \ in dir in target.txt automatically
- Bloatware Slayer 会自动纠正在 target.txt 中的路径被错误使用的转义符号
- Root implementation in module description will be updated in booting system each time
- 模块描述中的 Root 方案会在每次系统启动时更新
- Module Status will be updated real time as removing or disabling module
- 当移除或禁用模块时，模块状态会实时更新
- Add integrity verification to prove that the module has not been maliciously modified
- 新增完整性验证以证明模块未被恶意修改

### 1.0.5
- Support KernelSU officially
  正式支持 KernelSU
- Change the method of processing Apps in KernelSU and APatch
  from mknod to mount -o bind to improve compatibility
  更改在 KernelSU 和 APatch 中处理 APP 的方式
  从 mknod 变为 mount -o bind 以提升兼容性
- Optimize logic for some code
  优化部分逻辑
- Optimize the module status prompt content
  优化模块状态提示内容

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
