# Grid Demo Gallery

本示例参考 AG Grid 官网的 [Performance](https://www.ag-grid.com/example/)、[Finance](https://www.ag-grid.com/example-finance/)、[HR](https://www.ag-grid.com/example-hr/) 和 [Inventory](https://www.ag-grid.com/example-inventory/)。应用外壳沿用 UI Component gallery：左侧示例列表，右侧演示窗格，顶部主题切换。

## 实现范围

四个页面使用 `scoop.grid` 的公开接口，分别持有数据、查询、选择、展开和滚动状态。切换页面前提交当前单格编辑；校验失败时保留编辑现场。

| 场景 | 数据与交互 |
| --- | --- |
| Performance | 1,000 / 10,000 / 100,000 行，21 列，分组表头、国家与游戏分组、排序、筛选、选择、双向虚拟化 |
| Finance | 本地行情和持仓，价格、涨跌、盈亏、总值，按资产类别分组，手动刷新完整快照 |
| HR | 员工头像、职位、部门标签、组织树、雇佣类型、地点、入职日期、薪资、支付状态，单格编辑与展开／收起 |
| Inventory | 专辑封面、库存状态筛选、数量和价格编辑、上架／暂停／删除、版本明细、分页与重置样例 |

列工具和筛选工具复用 Grid 组件。Finance 不包含定时行情推送或 Sparkline；本例也不引入此前排除的多选区、填充、批量编辑、行拖动、跨行合并、图表、Excel／PDF、打印或公式功能。

业务数据仅用于演示，修改保存在当前进程内。封面、头像和应用图标使用本仓库生成的原创图形；启动时从 app 的 `Contents/Resources/assets` 读取，开发运行可显式指定 `--assets`。不依赖工作目录、开发机绝对路径或网络。

表格使用短表头分隔线、横向行边线、数字列对齐和跟随系统偏好的滚动条。Performance 与 Finance 使用 42 高的正文行，HR 使用 65 高的头像行、较小的大写表头与淡色隔行底纹，Inventory 使用 80 高的封面行、状态胶囊、图标操作与单行分页栏。颜色同时适配浅色和深色主题。共用表现由 `GridStyle` 配置；详情行始终占满网格视口，外层冻结列边界在详情区域内断开。

## 开发与打包

以下命令在仓库根目录运行，使用 `~/.scoop` 中已安装的 Scoop 开发工具链及系统库。更新工具链后需要重新构建并打包；既有 `.app` 中的可执行文件和资源不会自动更新。

```sh
~/.scoop/bin/scoop --version
~/.scoop/bin/scoop fmt examples/demo
~/.scoop/bin/scoop check examples/demo --tests --release
~/.scoop/bin/scoop test examples/demo --release
~/.scoop/bin/scoop run examples/demo --release -- --assets "$PWD/examples/demo/assets"
~/.scoop/bin/scoop bundle examples/demo --format app --output-dir "$PWD/dist"
```

macOS 入口在附着窗口前调用 Surface 的 FPS 诊断配置。以 `SCOOP_SURFACE_FPS=1 scoop run examples/demo --release -- --assets "$PWD/examples/demo/assets"` 启动时，stderr 输出 Metal 实际呈现帧率。默认关闭；静止窗口没有周期输出，样本的 `start`／`end` 可用于排除跨过静止期的区间。

2026-11-23 使用同一 Performance 页面完成滚动优化后的旧新版交替测量：60 Hz 本机常速约 44 → 60 FPS，十万行高速约 19 → 44.5–47.7 FPS。环境、滚动速度、分配量与剩余开销见 [性能记录](../../docs/PERFORMANCE.md)。

`Cone.toml` 引用同目录 `Bundle.toml`。Bundle 配置包含应用标识、名称、图标、封面、头像及资源说明。也可以对已经构建的可执行文件运行 `scoop bundle --executable … --config examples/demo/Bundle.toml --format app --output-dir …`。

打包完成后打开命令输出的 `Scoop Grid Demos.app`。Apple Silicon 上的项目构建默认位于 `dist/aarch64-apple-darwin/release/dev.scoop.grid.demos/app/Scoop Grid Demos.app`；使用 `--executable` 打包时，路径中的 profile 为 `prebuilt`。整个 app 可以移动到其他目录运行。

## 本机验证

2026-11-27，在 macOS Apple Silicon 上使用 `~/.scoop` 工具链 `0.0.0-dev.local.20261126202747424829`（Scoop `af7b7dc5c`）及其预编译系统库完成 release 验证：

- 变更文件格式检查、Grid 与 Demo 的 `scoop check --tests --release` 通过。Grid 的 191 项测试及 Demo 的 10 项测试全部通过；Demo 包括 8 项模型测试和全部 12 张头像、10 张封面的实际图片解码测试。
- 分隔线回归覆盖多个详情、部分滚出、收起恢复、上下固定区和 RTL；一亿行稀疏数据源验证只访问可见行元数据，不读取业务记录。
- 原生窗口已检查十万行双向滚动、手动行情刷新、HR 搜索保留祖先路径、组织树展开／收起和雇佣类型编辑；Inventory 的价格校验／保存、状态筛选、分页、多个详情展开／滚动／收起，以及浅色／深色外观均正常。无效价格会阻止切页，修正保存后错误提示清除。
- 使用当前工具链重建并打包后，HR 和 Inventory 的页面加载、图片及上述交互没有再出现异常退出。未取得旧包的异常栈，因此没有将旧故障归因于某个未经验证的运行时或资源问题。
- `.app` 搬离打包目录并从仓库外启动，头像和封面仍正常加载；最终包通过 `codesign --verify --deep --strict`。包内含应用图标、图片、资源说明和许可证。
