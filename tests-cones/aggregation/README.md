# 聚合面板与总计原生回归

本 Cone 使用生产 DataGrid、列面板、快速筛选及总计控件。通过真实 AppKit 无障碍动作选择聚合、操作查询，验证全筛选集总计、排序／分页复用、编辑失败与等待保存、动态文案、算术错误、空结果、清除聚合和关闭弹层。它只在本机 macOS 窗口运行一个 Application。

```sh
scoop check --tests --release tests-cones/aggregation
scoop test --release tests-cones/aggregation
```

普通数值、缺值、缓存及失败原子性在主 Cone 的 `GridAggregationTest` 中验证。原生回归沿现有公开无障碍测试接口操作实际控件，没有替代模型动作或模拟焦点完成。
