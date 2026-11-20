# Scoop Grid

基于 Scoop 原生 UI 的独立 DataGrid 库，公开包为 `scoop.grid`。本阶段范围见 [设计](docs/DESIGN.md)，实际交付与验证见 [进度](docs/PROGRESS.md)。

本库处于实现阶段。依赖 Scoop 现有的类型化数据、声明式 UI、原生输入、主题和无障碍能力，不兼容 AG Grid 的 JavaScript API。

已提供类型化本地模型、条件筛选面板、快速筛选和分页控件、双轴虚拟化 DataGrid、固定表头、逻辑 Start／End 冻结、按行列 key 定位、原生离屏单元格动作、二维键盘导航、自定义控件内部交互、类型化单格编辑／校验／异步提交、CSV／TSV 导出和单格粘贴解析，公开合同见 [SPEC.md](docs/SPEC.md)。完整编辑入口和分析功能继续实施。模型用法例如：

```scoop
import scoop.grid.*
import scoop.ui.ViewKey
import scoop.ui.component.*

class Product(val name: String, val price: Long)

fun main() {
    val products = TableRows([
        TableRecord(ViewKey.Text("apple"), Product("苹果", 12L)),
        TableRecord(ViewKey.Text("pear"), Product("梨", 9L))
    ])
    val model = DataGridState(products, [
        gridColumn<Product, String>(GridColumnId("name"), "商品", { p -> p.name }, gridTextValues()),
        gridColumn<Product, Long>(GridColumnId("price"), "价格", { p -> p.price }, gridLongValues())
    ])
    model.setQuery(GridQuery([GridSort(GridColumnId("price"))]))
    println(gridCsv(model.result.rows, model.columns))
}
```

本地模型验证：

```sh
scoop fmt .
scoop check --tests --release .
scoop test --release .
```

原生窗口使用 `dataGrid(model) { height = 480.0; handle = Some(handle) }`，其中 `handle` 是可选的 `DataGridHandle`。`handle.focusCell(GridCellAddress(rowKey, columnId))` 定位到真实单元格；焦点在成功布局后完成。Grid 使用应用的 `ThemeSource`，自定义单元格继续组合普通 View。

原生无障碍支持按行列读取离屏值，以及明确的 Realize／Reveal／Focus。读取不创建 View；显露使用表头和冻结区扣除后的实际空间，RTL 沿逻辑 Start／End 解析。`pendingCell`、`isPending` 与 `cancelFocus()` 同样覆盖原生焦点请求。

点击表头在升序、降序和无排序之间切换。默认按住 Shift 追加或调整多列排序，表头同时显示方向和优先级；可用 `multiSortModifier = GridMultiSortModifier.Primary` 改为平台主修饰键。真实表头焦点下的 Enter／Space 使用同一规则，并先处理当前编辑会话。

可在网格上方组合 `gridQuickFilter(model) { handle = Some(handle) }`，按 Enter 或“应用”提交快速筛选，输入草稿期间不执行查询；`gridPager(model) { handle = Some(handle) }` 提供结果条数、页大小和翻页。“全部”取消分页，仍使用同一个虚拟网格。两个控件通过同一 handle 检查单元格编辑，非法草稿或等待保存时不改变查询。`pageSizes` 可配置允许选择的正整数，外部当前值也会正确显示。

`gridFilterPanel(model) { handle = Some(handle) }` 编辑文本、整数、数值、日期、布尔和集合条件，可嵌套 AND／OR 组。修改草稿后点击“应用筛选”才更新查询；“还原草稿”恢复当前模型条件，“清除筛选”移除条件并保留排序与快速筛选。整数保留完整 Long 精度，日期复用现有 DatePicker；非法输入和反向区间保留原文供修正。通过同一 handle 处理当前单元格的校验和异步提交，等待保存后不会自动重放先前被拒绝的筛选动作。

集合条件的“加载候选”按完整本地数据读取该列，候选列表按视口构造。可搜索、选中当前列表或清空选择；搜索不会丢弃列表外已选值。重名标签仍保留不同的真实值，缺值和空字符串分别显示。数据或列定义替换后提示重新加载；查询、分页和调宽复用已加载的候选。自定义 `GridValues<T>` 须同时提供字面量解码 `literal` 和编码 `encode`，不使用格式化文字作为候选身份。

`gridColumnsPanel(model, handle) { ... }` 提供虚拟列列表、显隐、前移／后移、逻辑 Start／End 冻结、明确列宽、恢复列定义宽度和“适应视口”。列表同时标明列上仍在生效的排序和筛选。列宽输入按 Enter 或点击应用才发布，空值恢复 Fixed／Auto／Fraction；改变列状态保留查询结果。“适应视口”先满足最小宽度，再按当前宽度为权重分配余量，最大宽度受限时允许余白，最小宽度总和过大时保留横向滚动。

用户列操作经 `handle.setColumnState`、`handle.moveColumn` 和 `handle.fitColumns` 检查当前编辑及实际视口，返回 `GridColumnActionResult`。DataGrid 的 `minimumCenterWidth` 默认保留 80 个逻辑单位；冻结宽度增长侵入该空间时拒绝，窄窗口仍可解除或缩小冻结。程序主动更新模型可用 `setColumnStates` 一次安装完整列状态，任何一项无效时保留原状态。表头拖动、拖动调宽和内容自动测宽继续实施。

浏览使用方向键、Home／End、Primary＋Home／End、PageUp／PageDown 和 Tab。双击或 Enter／F2 进入可编辑列的编辑器；Enter／F2 也可进入自定义单元格的真实控件。编辑中的 Enter／Tab、点击其他格和失焦会先尝试提交，校验失败保留草稿。Escape 先交给输入法，再取消草稿；内部控件先处理自己的键盘与文本输入。

列通过 `edit = Some(gridEdit<Row, T>(...))` 明确声明编辑器、校验和有类型的应用回调。内置 `gridTextEditor`、`gridLongEditor`、`gridDoubleEditor` 复用原生文本编辑器；`gridBooleanEditor`、`gridDateEditor` 和 `gridChoiceEditor<T>` 分别复用 Checkbox、DatePicker 和 Select。`GridEditor<T>` 可接入自定义控件。应用用 `GridCommit<Row>.accept(nextSource)` 发布真实数据快照，或 `reject(message)` 保留草稿；异步 completion 只完成原会话一次，取消／卸载后的结果返回 false。`handle.editingCell`、`editError` 和 `isSubmitting` 可用于响应式状态栏。

[值编辑器示例](examples/editors/src/main.scoop) 展示布尔值、非空日期和类型化选项。日历与选项弹层先处理自己的 Escape；关闭后再按 Escape 取消当前格。选项弹层里的 Tab／Shift+Tab 关闭弹层后继续按行列导航。显示名相同的选项仍用真实 key 和类型化值区分。

[示例](examples/basic/src/main.scoop) 的名称和金额提供完整的取值、编辑、同步校验及不可变数据替换用法。原生回归分别覆盖受控文本事务和真实系统拼音输入；系统候选取消、选词后提交已经通过，输入源会恢复。

运行 [十万行示例](examples/basic/src/main.scoop) 与本机窗口回归：

```sh
scoop run --release examples/basic
scoop run --release examples/editors
scoop check --tests --release tests-cones/window
scoop test --release tests-cones/window
scoop check --tests --release tests-cones/controls
scoop test --release tests-cones/controls
scoop check --tests --release tests-cones/accessibility
scoop test --release tests-cones/accessibility
scoop check --tests --release tests-cones/query
scoop test --release tests-cones/query
scoop check --tests --release tests-cones/query-controls
scoop test --release tests-cones/query-controls
scoop check --tests --release tests-cones/filters
scoop test --release tests-cones/filters
scoop check --tests --release tests-cones/columns
scoop test --release tests-cones/columns
```

原生测试要求桌面已解锁且测试窗口能取得系统焦点。每个测试 Cone 在独立进程里运行一个 Application；`window` 保留宽表、导航、文本、系统拼音和剪贴板组合，`controls` 覆盖值编辑器的弹层与提交，`accessibility` 覆盖生产网格的原生定位、冻结区和节点生命周期，`query` 覆盖排序的原生点击、键盘和编辑门控，`query-controls` 覆盖快速筛选、分页与编辑提交的组合，`filters` 覆盖类型化条件、嵌套组合、集合候选和编辑提交，`columns` 覆盖虚拟列面板、调宽／显隐／顺序／冻结、窄窗口与编辑提交。

开发目录与 Scoop 源码并列：`scoop/`、`scoop-grid/`，已下载的原生依赖使用 `scoop-dep/`。本机验证使用 release 配置，先格式化、检查，再运行受影响的测试。构建产物与缓存不提交；原始验证日志放在相邻的 `scoop-work/`。

本地开发使用 `../scoop-work/grid/toolchain/bin/scoop`，配合 `--cache-dir ../scoop-work/grid/cache`；该副本已同步上游精确条目焦点、布局输入和共享祖先视口扩展。窗口回归与纯模型测试分别记录，完整阶段状态见进度文档。

明确排除高频增量更新，多区域选择、填充柄、整行／批量编辑、跨单元格撤销，行拖动、跨行合并，Sparkline、选区生成图表，Excel／PDF 导出、打印，以及公式和用户自定义计算列。
