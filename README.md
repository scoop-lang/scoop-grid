# Scoop Grid

基于 Scoop 原生 UI 的独立 DataGrid 库，公开包为 `scoop.grid`。本阶段范围见 [设计](docs/DESIGN.md)，实际交付与验证见 [进度](docs/PROGRESS.md)。

本库处于实现阶段。依赖 Scoop 现有的类型化数据、声明式 UI、原生输入、主题和无障碍能力，不兼容 AG Grid 的 JavaScript API。

已提供类型化本地数据模型、CSV／TSV 导出和单格粘贴解析，公开合同见 [SPEC.md](docs/SPEC.md)。模型用法例如：

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

开发目录与 Scoop 源码并列：`scoop/`、`scoop-grid/`，已下载的原生依赖使用 `scoop-dep/`。本机验证使用 release 配置，先格式化、检查，再运行受影响的测试。构建产物与缓存不提交；原始验证日志放在相邻的 `scoop-work/`。

本地开发目前使用 `../scoop-work/grid/toolchain/bin/scoop`，配合 `--cache-dir ../scoop-work/grid/cache`；该副本已同步上游精确条目焦点扩展。窗口组件仍在实施，现有模型与文本测试不能作为窗口交互验收。

明确排除高频增量更新，多区域选择、填充柄、整行／批量编辑、跨单元格撤销，行拖动、跨行合并，Sparkline、选区生成图表，Excel／PDF 导出、打印，以及公式和用户自定义计算列。
