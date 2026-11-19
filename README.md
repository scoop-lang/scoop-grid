# Scoop Grid

基于 Scoop 原生 UI 的独立 DataGrid 库，公开包为 `scoop.grid`。本阶段范围见 [设计](docs/DESIGN.md)，实际交付与验证见 [进度](docs/PROGRESS.md)。

本库处于实现阶段。依赖 Scoop 现有的类型化数据、声明式 UI、原生输入、主题和无障碍能力，不兼容 AG Grid 的 JavaScript API。

开发目录与 Scoop 源码并列：`scoop/`、`scoop-grid/`，已下载的原生依赖使用 `scoop-dep/`。本机验证使用 release 配置，先格式化、检查，再运行受影响的测试。构建产物与缓存不提交；原始验证日志放在相邻的 `scoop-work/`。

明确排除高频增量更新，多区域选择、填充柄、整行／批量编辑、跨单元格撤销，行拖动、跨行合并，Sparkline、选区生成图表，Excel／PDF 导出、打印，以及公式和用户自定义计算列。
