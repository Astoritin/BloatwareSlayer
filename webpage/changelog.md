## Bloatware Slayer / 干掉预装软件
A Magisk module to remove bloatware in systemless way / 一个无需修改 system 分区即可移除预装软件的 Magisk 模块

### 1.4.2

- Now, The default timeout of judging device bricked is 120 seconds (2 minutes) always
- Now, logging files located in `/data/adb/bloatwareslayer/logs` will be cleaned automatically as file counts reaching max value (30) during each time boot
- The path of saving last worked target list changes: `/data/adb/bloatwareslayer/logs/target_lw.conf` → `/data/adb/bloatwareslayer/last_worked/target_lw.conf`
- Remove logs from `action.sh`, now log will not be generated as clicking on the action/open button
- Fix a bug: Now, Bloatware Slayer will backup original `target.conf` properly as disabled "Auto update target list" feature
- Fix a bug: Now, Bloatware Slayer will skip unmounting properly as disabled "Disable module as bricked" feature
- Fix minor logic problems of brick rescue code
- Remove large amount of useless codes to reduce module file size
- Remove feature update module description as clicking on the remove/uninstall or disable button again since this feature is so useless
> Whether Zygisk Next or Magisk's Denylist Enforcing status is enabled or not is NOT related to the running status (theme) of Bloatware Slayer.
> This module only processes during system boot. Once finished boot, there is no operation for Bloatware Slayer to run in the background.
> "Updating module description realtime" seems completely redundant. Thus, I've removed it and won't reverse this change anymore.

- 判定设备变砖的默认倒计时统一为 120 秒 (2分钟)
- 在启动过程中，`/data/adb/bloatwareslayer/logs` 中的日志会在文件数到达最大值(30)时被自动清理
- 最近一次正确目标列表保存目录变更：`/data/adb/bloatwareslayer/logs/target_lw.conf` → `/data/adb/bloatwareslayer/last_worked/target_lw.conf`
- 移除来自 `action.sh` 的日志，现在在点击操作/打开按钮时不再生成任何日志
- 修复一个bug: 现在当禁用"自动更新目标列表"功能时，Bloatware Slayer 会正确备份原版的 `target.conf`
- 修复一个bug: 现在当禁用"变砖时自动禁用模块"功能时，Bloatware Slayer 会正确跳过 `service.sh` 的卸载操作
- 修复部分救砖逻辑代码的问题
- 移除大量无用代码以减小文件体积
- 由于过于无用，功能：卸载/禁用模块时更新模块描述又双叒叕被移除了
> 无论启用与否，Zygisk Next 的遵守排除列表状态和 Magisk 的遵守排除列表状态都与 Bloatware Slayer 的运行状态（主题）无关。
> 本模块仅在开机过程中进行处理，开机完成后 Bloatware Slayer 并没有任何需要在后台运行的操作。
> "模块描述实时刷新"这个功能就显得极其多余，因此我移除了，并且不会再撤销。
