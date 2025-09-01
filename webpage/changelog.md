## Bloatware Slayer / 干掉预装软件
A Magisk module to remove bloatware systemlessly / 一个无需修改 system 分区即可移除预装软件的 Magisk 模块

### 1.4.6

- Optimize umount logic: skip processing umount for apex/capex apps
- Optimize umount logic: now umount processing depends on the real using mode instead of the slay mode value of settings.conf
- Optimize minor code
- Add back /META-INF to fix the compatibility of KernelSU/APatch
---
- 优化umount逻辑：不再处理apex/capex条目
- 优化umount逻辑：现在umount将根据实际使用的模式自行判断，而不是settings.conf中slay_mode的值
- 优化少量代码
- 重新添加 /META-INF 以修复 KernelSU/APatch 的兼容性