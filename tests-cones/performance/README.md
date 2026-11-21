# 本机规模测量

这个原生 Cone 直接挂载库的 `dataGrid`，没有第二套网格实现。窗口固定为 1200×600 逻辑像素，使用 Shadcn 浅色与当前系统字体；每列 120、表头 32、纵向 overscan 56。普通表格预分配一万条记录，行高 48，含真实 Checkbox 和 Button。宽表格为十万行、300 列，最小行高 28，依次使用固定行高、两端冻结、两列内容行高；百万行场景使用惰性来源和相同 300 列、两端冻结，不预分配全部 Row。

每个场景先聚焦一个真实单元格，再执行 6 次预热、32 次横纵步进和 8 次远处跳转。观察器检查单格唯一挂载，统计实际创建、measure、行读取、挂载峰值，以及 Accepted 时内容矩形与当前 clip 相交的可见数量。保留数量包括 overscan、活动格和自动高度贡献列。观察器借用已有 Element 和 Canvas，不增加库的公开接口；测量包含这些观察成本。

`PERF_TIMES ui` 从外层布局开始到该帧 Accepted，覆盖 UI 布局、场景和提交；`request` 从滚动操作开始到 Accepted，另含调度等待。它们不代表 GPU 完成或显示器帧率。首次 Accepted 从挂载开始计时，不包含进程启动和模型准备。五个场景在同一进程顺序运行，后续场景共享已热的字体和图形缓存。

每个场景结束后等待 250 ms，再观察 100 ms 内没有新增呈现和帧请求；关闭后检查全部观测单元格、定位和编辑会话释放。完整本地查询另用预先准备的四万条记录测排序、两级分组、透视和恢复；年份／季度有 10 个实际组合，不补齐成笛卡尔积。计时结果只报告，不设置机器速度门槛。

先运行 `scoop fmt tests-cones/performance` 与 `scoop check tests-cones/performance --tests --release`，再 `scoop test tests-cones/performance --release --no-run`。将已链接产物用当前本机原生应用启动器运行，筛选 `GridPerformanceTest`。原始 stdout／测试事件及进程 RSS 采样保留在仓库外，环境和汇总见 [性能记录](../../docs/PERFORMANCE.md)。
