# Scoop Grid

基于 Scoop 原生 UI 的独立 DataGrid 库，公开包为 `scoop.grid`。本阶段范围见 [设计](docs/DESIGN.md)，实际交付与验证见 [进度](docs/PROGRESS.md)。

本库处于实现阶段。依赖 Scoop 现有的类型化数据、声明式 UI、原生输入、主题和无障碍能力，不兼容 AG Grid 的 JavaScript API。

已提供类型化本地模型、双轴虚拟化 DataGrid、固定表头、逻辑 Start／End 冻结、按行列 key 定位、二维键盘导航、自定义控件内部交互、类型化单格编辑／校验／异步提交、CSV／TSV 导出和单格粘贴解析，公开合同见 [SPEC.md](docs/SPEC.md)。完整编辑入口和分析功能继续实施。模型用法例如：

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

浏览使用方向键、Home／End、Primary＋Home／End、PageUp／PageDown 和 Tab。双击或 Enter／F2 进入可编辑列的编辑器；Enter／F2 也可进入自定义单元格的真实控件。编辑中的 Enter／Tab、点击其他格和失焦会先尝试提交，校验失败保留草稿。Escape 先交给输入法，再取消草稿；内部控件先处理自己的键盘与文本输入。

列通过 `edit = Some(gridEdit<Row, T>(...))` 明确声明编辑器、校验和有类型的应用回调。内置 `gridTextEditor`、`gridLongEditor`、`gridDoubleEditor` 复用原生文本编辑器；`GridEditor<T>` 可接入自定义控件。应用用 `GridCommit<Row>.accept(nextSource)` 发布真实数据快照，或 `reject(message)` 保留草稿；异步 completion 只完成原会话一次，取消／卸载后的结果返回 false。`handle.editingCell`、`editError` 和 `isSubmitting` 可用于响应式状态栏。

[示例](examples/basic/src/main.scoop) 的名称和金额提供完整的取值、编辑、同步校验及不可变数据替换用法。原生回归分别覆盖受控文本事务和真实系统拼音输入；系统候选取消、选词后提交已经通过，输入源会恢复。

运行 [十万行示例](examples/basic/src/main.scoop) 与本机窗口回归：

```sh
scoop run --release examples/basic
scoop check --tests --release tests-cones/window
scoop test --release tests-cones/window
```

开发目录与 Scoop 源码并列：`scoop/`、`scoop-grid/`，已下载的原生依赖使用 `scoop-dep/`。本机验证使用 release 配置，先格式化、检查，再运行受影响的测试。构建产物与缓存不提交；原始验证日志放在相邻的 `scoop-work/`。

本地开发使用 `../scoop-work/grid/toolchain/bin/scoop`，配合 `--cache-dir ../scoop-work/grid/cache`；该副本已同步上游精确条目焦点、布局输入和共享祖先视口扩展。窗口回归与纯模型测试分别记录，完整阶段状态见进度文档。

明确排除高频增量更新，多区域选择、填充柄、整行／批量编辑、跨单元格撤销，行拖动、跨行合并，Sparkline、选区生成图表，Excel／PDF 导出、打印，以及公式和用户自定义计算列。
