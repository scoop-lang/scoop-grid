# 行分组原生回归

使用生产 DataGrid、列面板和根组分页控件，覆盖离屏组通过系统元数据展开而不创建业务单元格、节点身份与退休、组选择及系统选择排除、真实按钮／Enter／F2／Space、二维方向键、非法草稿及异步保存门控、折叠后焦点回父组、组小计、页外固定记录、筛选恢复展开、列工具取消／重新分组、禁用及关闭。测试在本机 macOS 串行运行一个 Application。

```sh
scoop fmt tests-cones/grouping
scoop check --tests --release tests-cones/grouping
scoop test --release tests-cones/grouping
```

普通类型排序、聚合错误与缺值、路径、缓存、查询原子性、选择范围、视图恢复和导出在主 Cone 的 GridGroupingModelTest、GridGroupingStateTest、GridGroupingTextTest 中验证。原生测试的 setter 返回值只作为调用完成信号；实际行为由后续 Accepted 帧中的模型、节点和焦点验证。

本批本机 release 验收共 49 个阶段，约 1.64 秒完成，failures 为空、end／complete 齐全，进程正常退出。
