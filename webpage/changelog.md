## Bloatware Slayer / 干掉预装软件
A Magisk module to remove bloatware in systemless way / 一个无需修改 system 分区即可移除预装软件的 Magisk 模块

### 1.3.9

- Add **last time worked target list** features
- 新增 **最后一次正确目标列表** 功能
  set `last_worked_target_list=true` in `settings.conf`
  在 `settings.conf` 中设定 `last_worked_target_list=true`
  Only available as `disable_module_as_brick=false` (the behavior logical is NOT compatible as enabling this option)
  仅当 `disable_module_as_brick=false` 时可用 (启用该选项时行为逻辑不兼容)
  Bloatware Slayer will restore `target.conf` boot successfully at the last time
  Bloatware Slayer 会恢复上次成功启动系统时的 `target.conf` 版本
- Fix the bug as most of devices can NOT reboot (by `reboot -f`) as detecting being bricked
- 修复当检测到设备变砖时，大多数设备无法重新启动 (通过 `reboot -f`) 系统的bug
- Add X-plorer as open method for action.sh
- 为 action.sh 新增 X-plorer 作为打开方式
- remove command from module files `su -c` forever since `su -c` is not need anymore
- 由于不再需要 `su -c` ，已彻底移除
- minor code optimizing
- 优化部分代码
