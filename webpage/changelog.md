## Bloatware Slayer / 干掉预装软件
A Magisk module to remove bloatware in systemless way / 一个无需修改 system 分区即可移除预装软件的 Magisk 模块

### 1.4.3

- Right/True slay mode will be shown in module description now.
> Before this update, slay mode state showing on the module description is read in settings.conf.
> That means in weird cases like 0 APP is dealt with Mount Bind method and 4 APP(s) is dealt with Make Node method.
> Module description will show Hybrid even if only Make Node method is used before 1.4.3
> However it is obviously not a right feedback since which mode Bloatware Slayer used depends on the real processing instead of setting in config file.
- Optimize minor code

- 现在模块描述中会展示正确/实际使用的模式。
> 在此更新之前，显示在模块描述中的模式取决于Bloatware Slayer 的配置文件 settings.conf 中的设定
> 这意味着在 1.4.3 之前，极端情况下（例如没有APP被 Mount Bind 方法处理，有4个APP被 Make Node 方法处理）模块描述仍会显示为复合模式 (Hybrid)
> 然而很显然，这样的反馈信息并不正确。在 Bloatware Slayer 的模块描述中，处理模式应该取决于实际过程中的所用的方法，而不是配置文件的设置。
- 优化少量代码
