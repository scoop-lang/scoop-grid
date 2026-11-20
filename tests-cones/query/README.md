# 生产 DataGrid 查询交互回归

使用生产 `dataGrid`、五条真实记录、三个列区和 AppKit 原生事件。每个测试进程只运行一个 Application，窗口需要能正常取得系统焦点。

```sh
scoop check --tests --release tests-cones/query
scoop test --release tests-cones/query
```

29 个检查阶段覆盖普通点击和 Shift 多列排序、排序维度的追加／改向／移除、同值记录的稳定次序、方向与优先级标题、真实表头焦点下的 Enter／Space 和按键重复，以及配置 Primary 后的 Command 操作、RTL、冻结区、不可排序列与禁用。

编辑组合检查非法草稿阻止排序、异步保存期间不重复提交、不在保存完成后补执行已拒绝的点击，以及之后的新点击正常排序。检查结束时直接关闭仍有焦点的 Grid，验证输入观察者的卸载边界。

原生辅助代码仅构造带修饰键的 `NSEvent`；查询结果、顺序、语义标题与焦点均从生产模型和公开 AppKit 无障碍协议读取。完整阶段状态见 [实施进度](../../docs/PROGRESS.md)。
