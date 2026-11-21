# 网格 View 插槽回归

本 Cone 挂载同一个生产 `dataGrid`，用真实 AppKit 节点、控件动作和焦点检查工具栏、底栏、空状态、加载及错误 View。只在本机 macOS 原生窗口运行一个 Application。

```sh
scoop check --tests --release tests-cones/slots
scoop test --release tests-cones/slots
```

场景覆盖固定外框中的实际几何、表头偏移、RTL、插槽身份与退休、加载 busy 和错误优先级；同一网格的查询结果、滚动和非法编辑草稿在切换插槽时保持。网格禁用时真实工具栏／重试按钮仍可执行；空状态按钮清除实际查询。工具栏和底栏占满高度时，原列头不能取得原生焦点。外部焦点提交拒绝、异步保存期间显示状态与操作底栏、失败提示和关闭清理沿真实网格会话验证。

通过已有公开无障碍测试接口读取节点和 Frame；附加的两个原生函数仅按公开 Table 角色取得同一表格及读取 busy 描述，不遍历记录内容或调用 Grid 内部方法。
