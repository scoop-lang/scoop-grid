# 业务行选择原生回归

本 Cone 使用生产 `dataGrid`，通过本机 AppKit 的真实行对象、Checkbox、鼠标和键盘验证选择。独立进程运行一个 Application，要求桌面已解锁且窗口能获得系统焦点。

```sh
scoop check --tests --release tests-cones/selection
scoop test --release tests-cones/selection
```

覆盖一亿行的离屏 SetSelected、原生已选行列表、焦点与滚动不变；当前页三态、固定行去重、不可选记录、Shift 范围、Shift＋Space、过滤／分页保留和真实删除；RTL、隐藏首列、隐藏 Checkbox、单选、禁用、模型替换，以及无效编辑、异步提交和卸载的组合。

虚拟节点元数据在 UI 事件回调之外查询。测试按公开行索引接口取得单个行对象，寻找表头时跳过正文表格，不递归枚举整个逻辑数据集。坐标取自真实 Checkbox 的原生 Frame，之后发送正常鼠标事件；测试不调用 Grid 内部选择实现来代替界面操作。

原 39 个阶段还覆盖带真实单元格焦点切换网格／行选择文案：保留的 Table 与 Checkbox 节点报告新名称，列头报告新说明，原查询结果和列状态身份不变；随后恢复默认文案并继续分页和选择。
