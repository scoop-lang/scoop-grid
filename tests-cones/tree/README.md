# 树数据原生回归

使用生产 DataGrid、列面板和根节点分页控件，验证离屏层级元数据、真实展开按钮与 Alt＋方向键、可编辑层级列、上下文祖先及选择排除、非法草稿与异步保存、折叠焦点回父、固定业务行、小计、筛选恢复、禁用和节点退休。测试在本机 macOS 串行运行一个 Application。

```sh
scoop fmt tests-cones/tree
scoop check --tests --release tests-cones/tree
scoop test --release tests-cones/tree
```

普通拓扑、深树、环及缺失父引用、稳定排序、聚合、缓存、选择和导出在主 Cone 的 GridTreeModelTest、GridTreeStateTest、GridTreeTextTest 中验证。原生动作返回值只表示调用完成，实际行为按后续 Accepted 帧中的模型、节点和焦点断言。

本机 macOS aarch64 最终回归 45 个阶段全部通过，约 1.53 秒完成，failures 为空且 begin／end／complete 齐全；已有分组回归 49 个阶段同时通过。原始报告位于仓库外并在批次提交前清理。
