# 查询控件原生回归

使用生产 `gridQuickFilter`、`gridPager`、`dataGrid`，在一个 Application 中运行 62 个阶段。桌面需允许窗口呈现并取得系统焦点。

```sh
scoop check --tests --release tests-cones/query-controls
scoop test --release tests-cones/query-controls
```

回归从公开 AppKit 无障碍协议读取实际文字、启用状态和焦点，并通过原生动作、键盘和 NSTextInputClient 操作生产控件。覆盖分页点击与键盘、查询结果复用、输入草稿、受控组合文字与取消、Enter 应用、快速筛选与原条件合并、每次动作一次查询、外部条件同步、零条结果、清除、“全部”、页大小切换、外部指定的非列表页大小、禁用与模型替换。

单元格编辑组合验证非法值拒绝筛选、等待保存时禁用、重复操作不重复保存、保存成功后保留未应用的筛选草稿，以及新操作正确应用。末尾在 Grid 表头仍持有真实焦点时关闭根。这里的组合文字是受控输入；真实系统拼音继续由 `tests-cones/window` 覆盖。

原始报告放在仓库外，验证结果记录在 [实施进度](../../docs/PROGRESS.md)。
