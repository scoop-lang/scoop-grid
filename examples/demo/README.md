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

## 开发与打包

以下命令在仓库根目录运行，使用已安装的 Scoop 开发工具链及系统库：

```sh
scoop fmt examples/demo
scoop check examples/demo --tests --release
scoop test examples/demo --release
scoop run examples/demo --release -- --assets "$PWD/examples/demo/assets"
scoop bundle examples/demo --format app --output-dir "$PWD/dist"
```

macOS 入口在附着窗口前调用 Surface 的 FPS 诊断配置。以 `SCOOP_SURFACE_FPS=1 scoop run examples/demo --release -- --assets "$PWD/examples/demo/assets"` 启动时，stderr 输出 Metal 实际呈现帧率。默认关闭；静止窗口没有周期输出，样本的 `start`／`end` 可用于排除跨过静止期的区间。

`Cone.toml` 引用同目录 `Bundle.toml`。Bundle 配置包含应用标识、名称、图标、封面、头像及资源说明。也可以对已经构建的可执行文件运行 `scoop bundle --executable … --config examples/demo/Bundle.toml --format app --output-dir …`。

打包完成后打开命令输出的 `Scoop Grid Demos.app`。Apple Silicon 上的项目构建默认位于 `dist/aarch64-apple-darwin/release/dev.scoop.grid.demos/app/Scoop Grid Demos.app`；使用 `--executable` 打包时，路径中的 profile 为 `prebuilt`。整个 app 可以移动到其他目录运行。

## 本机验证

2026-11-22，在 macOS Apple Silicon 上使用 release 构建验证：

- `scoop fmt`、`scoop check --tests --release` 和 8 项模型测试通过，覆盖大数据源随机访问、分组与搜索组合、金额编辑与筛选单位、行情刷新后的查询／选择、组织树祖先路径、支付状态搜索、库存删除／重置，以及切页后的独立状态。
- 原生窗口已检查十万行切换和滚动、手动行情刷新、组织树展开与搜索、雇佣类型编辑、库存价格编辑与校验、明细表、暂停／删除／重置、深色主题，以及列／筛选工具面板。无效编辑会阻止切页，按 Esc 取消后会清除单元格和应用底部的错误提示。
- 已通过项目入口和预构建可执行文件两种方式打包 `.app`，移动 app 后头像与封面仍能正常加载；最终 app 通过 `codesign --verify --deep --strict`。
