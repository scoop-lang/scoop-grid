# Scoop Grid

基于 Scoop 原生 UI 的独立 DataGrid 库，公开包为 `scoop.grid`。本阶段范围见 [设计](docs/DESIGN.md)，实际交付与验证见 [进度](docs/PROGRESS.md)。

本库处于实现阶段。依赖 Scoop 现有的类型化数据、声明式 UI、原生输入、主题和无障碍能力，不兼容 AG Grid 的 JavaScript API。

已提供类型化本地模型、条件筛选面板、快速筛选和分页控件、双轴虚拟化 DataGrid、固定表头、逻辑 Start／End 冻结、按行列 key 定位、原生离屏单元格动作、二维键盘导航、自定义控件内部交互、类型化单格编辑／校验／异步提交、业务行单选／多选、CSV／TSV 导出和单格粘贴解析，公开合同见 [SPEC.md](docs/SPEC.md)。矩形选择与分析功能继续实施。模型用法例如：

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
    ], headers = Some([
        GridHeaderNode.Group(GridColumnGroupId("product"), "商品信息", [
            GridHeaderNode.Column(GridColumnId("name")),
            GridHeaderNode.Column(GridColumnId("price"))
        ])
    ]))
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

`DataGridState(..., rowSelection = GridRowSelectionMode.Multiple)` 启用业务行多选，`Single` 启用单选，默认 `Disabled`。首个可见业务列显示 Checkbox，Shift＋点击按当前结果顺序扩展行范围；浏览格的 Shift＋Space 切换该行。多选表头的三态 Checkbox 只选择当前页的合格记录，不包含额外固定行。`selectable = Some { row -> ... }` 可限定不可变记录的选择资格；`selectionCheckboxes = false` 隐藏控件，保留选中底色和原生行选择动作。

应用读取 `selectedRowKeys`／`isRowSelected(key)`，或订阅 `onSelectionChange`；主动更新使用 `setRowSelected`、`setSelectedRows`、`selectRowRange`、`selectPageRows` 与 `clearRowSelection`。过滤、排序、翻页和固定保留业务 key 选择，完整本地来源真正删除记录时清理。选择与当前单元格焦点独立，不重跑查询、不因选择离屏记录而构造 View。默认全部可选时，单行选择和表头状态计算也不扫描数据来源。

界面操作可用 `handle.setRowSelected`、`handle.selectPageRows` 和 `handle.clearRowSelection`，未挂载或禁用时返回 `GridRowActionResult.Rejected`。真实点击遵守当前编辑的提交／拒绝规则；直接模型和原生行选择动作本身不会隐式改写编辑草稿。[十万行示例](examples/basic/src/main.scoop) 展示已选条数与清空入口。

点击表头在升序、降序和无排序之间切换。默认按住 Shift 追加或调整多列排序，表头同时显示方向和优先级；可用 `multiSortModifier = GridMultiSortModifier.Primary` 改为平台主修饰键。真实表头焦点下的 Enter／Space 使用同一规则，并先处理当前编辑会话。

可在网格上方组合 `gridQuickFilter(model) { handle = Some(handle) }`，按 Enter 或“应用”提交快速筛选，输入草稿期间不执行查询；`gridPager(model) { handle = Some(handle) }` 提供结果条数、页大小和翻页。“全部”取消分页，仍使用同一个虚拟网格。两个控件通过同一 handle 检查单元格编辑，非法草稿或等待保存时不改变查询。`pageSizes` 可配置允许选择的正整数，外部当前值也会正确显示。

`gridFilterPanel(model) { handle = Some(handle) }` 编辑文本、整数、数值、日期、布尔和集合条件，可嵌套 AND／OR 组。修改草稿后点击“应用筛选”才更新查询；“还原草稿”恢复当前模型条件，“清除筛选”移除条件并保留排序与快速筛选。整数保留完整 Long 精度，日期复用现有 DatePicker；非法输入和反向区间保留原文供修正。通过同一 handle 处理当前单元格的校验和异步提交，等待保存后不会自动重放先前被拒绝的筛选动作。

集合条件的“加载候选”按完整本地数据读取该列，候选列表按视口构造。可搜索、选中当前列表或清空选择；搜索不会丢弃列表外已选值。重名标签仍保留不同的真实值，缺值和空字符串分别显示。数据或列定义替换后提示重新加载；查询、分页和调宽复用已加载的候选。自定义 `GridValues<T>` 须同时提供字面量解码 `literal` 和编码 `encode`，不使用格式化文字作为候选身份。

`gridColumnsPanel(model, handle) { ... }` 提供虚拟列列表、显隐、前移／后移、逻辑 Start／End 冻结、明确列宽、恢复列定义宽度和“适应视口”。列表同时标明列上仍在生效的排序和筛选。列宽输入按 Enter 或点击应用才发布，空值恢复 Fixed／Auto／Fraction；改变列状态保留查询结果。“适应视口”先满足最小宽度，再按当前宽度为权重分配余量，最大宽度受限时允许余白，最小宽度总和过大时保留横向滚动。

用户列操作经 `handle.setColumnState`、`handle.moveColumn` 和 `handle.fitColumns` 检查当前编辑及实际视口，返回 `GridColumnActionResult`。DataGrid 的 `minimumCenterWidth` 默认保留 80 个逻辑单位；冻结宽度增长侵入该空间时拒绝，窄窗口仍可解除或缩小冻结。程序主动更新模型可用 `setColumnStates` 一次安装完整列状态，任何一项无效时保留原状态。

列面板的“适应可见内容”只测当前列的表头、当前呈现行和声明的文字样本，空结果也可使用。它复用真实单元格的自然宽度测量，自定义控件同样生效；横向离屏的目标列只为这些行准备内容，纵向 overscan 和其他离屏行不会参与。结果遵守最小／最大宽度和冻结上限，在布局成功后保存，后续滚动不会继续调宽。

程序可调用 `handle.fitColumnToContent(id)`，返回 `GridColumnFit`；在组件中读取其可观察 `result`，可区分 `Pending`、`Applied(width)`、`Rejected(message)` 和 `Cancelled`，其中宽度使用逻辑单位。`cancel()` 取消等待中的请求，后来的有效请求替换旧请求。非法编辑、组合输入、等待保存或隐藏列会立即拒绝；等待期间的数据、列配置、模型或字体变化会取消旧结果。自定义 View 按通常的无界横向约束提供自然宽度。

拖动表头逻辑 End 边界可以调宽，RTL 下手柄位于左侧。手柄可通过 Tab 聚焦，左右方向键每次调整 10 个逻辑单位，Home 恢复列定义宽度；原生无障碍客户端也可读取和设置数值。冻结列到达中心保留空间的上限后停止增长。Escape、失焦、禁用或卸载取消拖动并恢复原宽度；期间应用已改列状态时保留应用结果。非法编辑、组合输入和等待保存会阻止新调宽，保存后需重新操作。

拖动表头主体超过水平阈值后显示插入线，在同一冻结区域内释放即完成重排；目标列的逻辑前／后半边决定插到该列之前／之后。中心区边缘会自动横向滚动，来源列离屏后仍可继续拖动，停止后不持续绘制。跨冻结区、移出表头、Escape 或焦点离开取消拖动；外部列配置更新始终保留。拖列使用相同的编辑门控，保持隐藏列及其他列的相对顺序、查询结果和排序优先级。普通表头点击仍用于排序，键盘和无障碍用户可使用列工具的前移／后移。

`headers` 可声明多级 `GridHeaderNode` 树，恰好覆盖所有列。组内叶列只在其父组内移动，拖动组标题则移动整个逻辑组，包括隐藏成员及其他冻结片段；也可用 `handle.moveColumnGroup(id, index)` 或列工具中的组移动按钮。`index` 指移动后首叶在完整 `columnState` 中的位置，必须是同级边界；成员关系变化通过 `replaceColumns(values, headers = Some(tree))` 明确发布。

`headerHeight` 是每层高度，浅层叶占满其余层；冻结组可显示为 Start／中心／End 三个片段。横向离屏组不创建视图，宽组标题留在当前可见片段。原生节点发布实际跨度与祖先表头关系，隐藏和卸载后旧关联会撤下。组标题不参与单列内容测宽。[十万行示例](examples/basic/src/main.scoop) 展示三级表头与固定列。

`rowSizing` 默认是 `GridRowSizing.Fixed`，全部行使用 `rowHeight`。可设为 `GridRowSizing.Explicit { row -> ... }`，按记录返回正的有限高度；或设为 `GridRowSizing.Content([GridColumnId("name")])`，让指定列的真实内容撑高整行。后者的默认文本会自动换行，编辑器也参与同一高度测量；`rowHeight` 是最小高度。所有高度使用逻辑单位，并随主题密度缩放。

可变模式把 `rowHeight` 作为未测量行的估计值，滚动范围随实际测量更新。只为当前行窗口、overscan 和活动行准备内容；指定的高度贡献列即使横向离屏也会测量，隐藏后不再贡献，其他列继续虚拟化。数据、列宽、字体和密度改变时，按最近成功呈现的行 key 与行内偏移保持阅读位置；新的滚动和定位请求优先。[示例](examples/basic/src/main.scoop) 的长名称可用于观察换行、调宽和编辑后行高变化。

`DataGridState(..., pinnedRows = GridPinnedRows(top = [...], bottom = [...]))` 按稳定行 key 指定顶部和底部固定行，两区之间也不能重复。固定行从完整查询结果取得，可以显示当前页之外的记录；当前页中的同一记录从正文移出。固定配置保留自己的顺序，筛选暂时隐藏不匹配记录，真实数据删除则清理 key。`result.rows` 是当前 Top／Body／Bottom 呈现序列，`result.pageRows` 保留原查询页；两者都不改变查询总数和页数。

用户操作调用 `handle.pinRow(key, GridRowPin.Top／Bottom／None)`，返回 `GridRowActionResult`，先检查当前编辑；校验失败、组合输入或等待保存时拒绝本次动作，保存后需要重新操作。应用可用 `model.setPinnedRows(...)` 一次替换配置，或 `model.pinRow(...)` 主动更新。移动固定区域仍使用同一个真实单元格；固定、显式和内容行高均适用，内容测宽只采样三段中实际可见的行。

固定行仅跟随横向滚动，Start／End 冻结格两轴都保持位置。可用高度不足时先分配 Top，再分配 Bottom，正文允许零高；固定区从起点裁剪，不另建滚动区。[示例](examples/basic/src/main.scoop) 提供独立于 Grid 的首／末记录固定按钮，裁剪后仍可解除固定。

`columnSpans = Some { row -> [GridColumnSpan([nameId, amountId])] }` 为一行声明有序的跨列范围。首列是唯一锚点，显示其真实内容；所有成员须可见、顺序连续且处于同一冻结区。隐藏、移动、冻结或移除成员使这一条规则暂时失效，恢复条件后重新生效；当前有效范围不能重叠。跨度内的导航和原生动作统一定位锚点，横向部分可见时仍保持一个单元格实例。

跨列格只读，拆分后才恢复各列的编辑能力；外部规则变化会结束受影响的旧编辑。自动行高按合并后的宽度测量，多个高度贡献列落在同一跨度时只测一次；单列内容测宽跳过合并格，CSV 仍按各列原值输出。[十万行示例](examples/basic/src/main.scoop) 可切换名称／金额的跨列说明。

浏览使用方向键、Home／End、Primary＋Home／End、PageUp／PageDown 和 Tab。双击或 Enter／F2 进入可编辑列的编辑器；Enter／F2 也可进入自定义单元格的真实控件。编辑中的 Enter／Tab、点击其他格和失焦会先尝试提交，校验失败保留草稿。Escape 先交给输入法，再取消草稿；内部控件先处理自己的键盘与文本输入。

在文本、整数或浮点格上直接键入会从空草稿开始，以新输入替换原值；Enter／F2 仍从原值开始。首字、Unicode 和系统输入法的组合通过同一原生连接交给正常 Input／Textarea，编辑器内撤销可回到空草稿，取消编辑则保留原记录。非法数字保留输入文字供修正。只读格、跨列显示、布尔／日期／选项等非文本编辑器不通过键入改值。

自定义 `GridEditor<T>` 可实现 `startInput(state): TextInputStartOptions?`，采用传入的 `TextEditorState`，返回与真实编辑器相同的 policy／multiline 配置；默认 None 拒绝直接开始。不要写入旧值或重放首字符。取消、禁用和卸载会清理尚未接管的输入状态。

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
scoop check --tests --release tests-cones/sizing
scoop test --release tests-cones/sizing
scoop check --tests --release tests-cones/groups
scoop test --release tests-cones/groups
scoop check --tests --release tests-cones/heights
scoop test --release tests-cones/heights
scoop check --tests --release tests-cones/pinned
scoop test --release tests-cones/pinned
scoop check --tests --release tests-cones/spans
scoop test --release tests-cones/spans
scoop check --tests --release tests-cones/selection
scoop test --release tests-cones/selection
```

原生测试要求桌面已解锁且测试窗口能取得系统焦点。每个测试 Cone 在独立进程里运行一个 Application；`window` 保留宽表、导航、文本、系统拼音和剪贴板组合，`controls` 覆盖值编辑器的弹层与提交，`accessibility` 覆盖生产网格的原生定位、冻结区和节点生命周期，`query` 覆盖排序的原生点击、键盘和编辑门控，`query-controls` 覆盖快速筛选、分页与编辑提交的组合，`filters` 覆盖类型化条件、嵌套组合、集合候选和编辑提交，`columns` 覆盖虚拟列面板、显隐／顺序／冻结、表头鼠标与键盘调宽、拖列与边缘自动滚动、取消恢复、RTL／密度、窄窗口和编辑提交，`sizing` 覆盖真实内容测宽、可见行边界、请求失效和模型／字体／编辑的组合，`groups` 覆盖多级表头、跨冻结区片段、组移动、宽组焦点、原生跨度与祖先表头关系，`heights` 覆盖显式／自动行高、阅读锚点、离屏贡献列、编辑器和原生定位的组合，`pinned` 覆盖顶部／底部固定、分页去重、筛选／删除、可变高度、原生身份与编辑保留，以及零正文和三段内容测宽。

`spans` 覆盖跨列锚点与导航、远端原生定位、规则变化、只读编辑限制，以及固定行列、自动行高、内容测宽、多级表头和零宽成员的组合。

开发目录与 Scoop 源码并列：`scoop/`、`scoop-grid/`，已下载的原生依赖使用 `scoop-dep/`。本机验证使用 release 配置，先格式化、检查，再运行受影响的测试。构建产物与缓存不提交；原始验证日志放在相邻的 `scoop-work/`。

本地开发使用 `../scoop-work/grid/toolchain/bin/scoop`，配合 `--cache-dir ../scoop-work/grid/cache`；该副本已同步上游精确条目焦点、布局输入和共享祖先视口扩展。窗口回归与纯模型测试分别记录，完整阶段状态见进度文档。

明确排除高频增量更新，多区域选择、填充柄、整行／批量编辑、跨单元格撤销，行拖动、跨行合并，Sparkline、选区生成图表，Excel／PDF 导出、打印，以及公式和用户自定义计算列。
