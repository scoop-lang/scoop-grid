# 订单主从详情

使用生产 DataGrid 展示 24 条订单，默认每页 10 条并展开首单。详情包含配送备注、优先级 Select 和应用明确创建的交付子表；子表数量支持单格校验、保存与合计。应用通过 OrderDetail 保留备注与已保存数据，关闭详情时只结束当前挂载和草稿。

使用对应的正式 Scoop 工具链：

```sh
scoop check --release examples/details
scoop run --release examples/details
```

可以通过客户列旁的按钮或 Alt＋Enter 展开／收起；父格上的 Alt＋Down 进入详情，Escape 在内部控件处理之后返回父行。工具栏提供首单展开、进入详情、收起全部及固定父行；快速筛选和分页不会把详情算成额外订单。右侧继续使用同一个列工具面板。

子表选择数量格后按 F2，输入正整数并提交；零、负数及无效文字保留错误草稿。备注与已接受的数量在折叠再展开后保留，未提交草稿不保存。

实现入口：[订单窗口](src/main.scoop)、[应用拥有的详情状态](src/detail.scoop)。
