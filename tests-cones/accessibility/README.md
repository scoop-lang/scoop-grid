# 生产 DataGrid 原生无障碍回归

使用 `dataGrid`、真实 Label 和 AppKit 的公开无障碍协议，描述一亿行、300 列，Start／End 各冻结一列。每个测试进程运行一个 Application；桌面需能让窗口正常呈现并取得焦点。

```sh
scoop check --tests --release tests-cones/accessibility
scoop test --release tests-cones/accessibility
```

27 个阶段覆盖首次呈现的三个列区、离屏元数据查询、同步 Realize、正常回收、Reveal、精确 Focus 与清除、外部焦点及显式取消、LTR／RTL 冻结区、禁用、隐藏列、删行、同 key 重建和根关闭。Reveal 完成以动作结果和实际 Frame 共同判断，存在几何本身不代表目标已完整显露。

元数据查询不创建 View；Realize 只新增目标格。整个过程累计读取少于 400 行、创建少于 2400 格，每个业务地址最多一个挂载，关闭后全部释放。测试不遍历完整原生表格子树，也不把按需呈现规模当作全量查询性能。

这里验证本机公开原生协议和真实焦点，不代替跨进程 AX 客户端或 VoiceOver 操作；完整阶段状态与验证结果记录在 [实施进度](../../docs/PROGRESS.md)。
