# 主从详情原生回归

以生产 DataGrid 显示十万条惰性父记录；详情包含真实文本输入、Select 弹层和应用明确创建的可编辑嵌套 DataGrid。验证详情按需构造、独立的行语义、Alt＋Enter／Alt＋Down、Tab 与 Escape、自然高度、父行固定、横向滚动、RTL、宽度变化、编辑门控、禁用和卸载。

嵌套草稿、等待保存和打开弹层时关闭详情，必须清理旧挂载并拒绝迟到保存；聚焦详情被收起或父记录删除时，核对真实父格或网格入口焦点。父网格不接管子网格的提交，也不把详情暴露成可编辑格。

```sh
scoop fmt tests-cones/details
scoop check --tests --release tests-cones/details
scoop test --release tests-cones/details
```

本 Cone 在本机 macOS 串行运行一个 Application，按 Accepted 帧核对实际模型、原生节点及系统焦点。纯模型、稀疏索引、文本操作和视图恢复在主 Cone 测试。

原生查询使用按行入口读取父记录和详情，并跳过窗口中的整表枚举来寻找弹层。纯展示内容使用真实容器焦点，验证进入、Escape 返回及恢复交互内容；父表的每个详情只有一条原生 Row，嵌套表格保留自己的行。

本机 macOS aarch64 的 release 回归已通过 57 个检查阶段，约 2.38 秒完成；报告 failures 为空，end／complete 齐全。行高 42 阶段和键盘／真实拼音 148 阶段组合回归同步通过。原始报告放在仓库外并于批次结束清理。
