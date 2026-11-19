# Scoop Grid 公开合同

本文件随实现记录可用 API；完整阶段设计见 [DESIGN.md](DESIGN.md)。公开包为 `scoop.grid`，作为普通库依赖 Scoop UI，不增加语言或 runtime 机制。

## 类型化列

`GridColumnId` 是非空字符串组成的稳定列身份，标题不参与身份。`gridColumn<Row, T>` 将取值、格式化、比较和查询字面量解析绑定到同一个 `T`；不同值类型的列通过 `GridColumn<Row>` 共同操作，不暴露动态单元格值容器。

`GridValues<T>` 定义值的类型、文字、比较和字面量解码。内置文本、Long、Double、Boolean 和 LocalDate 值描述；`nullableGridValues` 在原有类型上区分缺值和普通值。文本匹配可区分大小写或进行 ASCII 大小写折叠；非 ASCII 字符按原字符匹配，不宣称支持语言相关排序／大小写规则。数值排序不经过格式化文本，Long 保留完整整数精度。

`GridColumn` 同时提供显示 View、无须创建 View 的文字和可选数值。自定义 `cell` 覆盖显示，不改变排序、筛选、复制所依据的数据。操作列由 `gridActionColumn` 创建，不支持排序、筛选或导出，错误调用抛出 `IllegalArgumentException`。

## 查询

`GridQuery` 包含稳定多列排序、AND／OR 筛选树、快速筛选和 `GridPagination`。筛选支持比较、闭区间、集合、缺值及文本包含／前缀／后缀。日期使用 `LocalDate` 语义，数值支持精确整数和浮点字面量；列入口拒绝不匹配的字面量、反向区间、重复排序及未知列。

普通比较和区间不匹配缺值。缺值可以通过 `Missing` 或集合中的 `Empty` 明确匹配。`NotEqual` 同样不包含缺值。缺值的排序位置由列的 `missingLast` 决定，在升序和降序中保持不变。排序比较相等时保持原始行次序。

快速筛选对可导出列的数据文字进行 ASCII 大小写折叠后包含匹配，任意一列匹配即保留该行。它不创建单元格 View。

`GridPagination.Disabled` 返回全部筛选后行；`Page(index, size)` 要求非负页索引、正页大小，超出末页时夹到末页，空结果归零。查询条件变动回到第一页，单独换页不会重跑排序和筛选。

## 本地状态与数据

`DataGridState<Row>` 消费不可变 `TableSource<Row>`，应用可复用 `TableRows`／`TableRecord`。来源必须履行 `TableSource` 的稳定、显式、唯一 key 与互逆索引合同；`TableRows` 已在构造时验证，不重复全量检查该事实。

状态通过 `setQuery`、`setPage`、`setPagination`、`toggleSort`、`replaceData` 和 `replaceColumns` 更新。模型在动作入口计算并发布一个完整结果，属性读取不执行查询。查询失败保持旧快照。来源、列集合和查询条件未变时复用已有顺序，页码与列外观动作不使查询失效。

`GridResult<Row>` 暴露本页 `rows`、全部筛选结果 `ordered`、`totalRows` 和 `pageCount`。`columns` 返回当前列定义，`columnState` 数组顺序就是用户的列顺序。宽度受已有 `TableColumnSize` 限制；列可以显示／隐藏、移动、设置逻辑 Start／End 冻结。设置宽度、移动和显隐不会访问行数据。实际视口冻结几何由布局批次补充。

替换列先验证新集合，保留存活列的宽度、顺序、显隐和冻结，新增列追加。查询中删除的列引用被删除；AND／OR 中删除后为空的组合被移除，不伪造恒真子句。存活列的类型合同变化后重新检查其查询，错误时整个替换不发布。选择、编辑和层级行为尚未由本文件发布。

## 文本导出与单格粘贴解析

`gridCsv(rows, columns, includeHeaders = true)` 输出 CSV 字符串，使用逗号、CRLF、标准双引号转义，每条记录以 CRLF 结束。`gridTsv(rows, columns)` 输出适合矩形复制的制表符分隔文本，行间使用 LF，不额外增加末行换行。调用者明确提供数据范围及列顺序；例如本页使用 `model.result.rows`，全部筛选结果使用 `model.result.ordered`。函数不取数、不持有文件或剪贴板、不创建 View，也不建立额外的单元格矩阵。

不允许导出的列被省略；全部列均不可导出时报告错误。可导出列必须提供数据文字，缺值由该列正常格式化。逗号／制表符、双引号、CR 和 LF 按对应格式加引号。不存在公式解析或导出为 Excel 公式的特殊分支。

`parseGridCellPaste(text)` 返回 `GridCellPaste.Value` 或带原因的 `Rejected`。允许标准引用字段、字段内部换行、转义双引号，以及一个可选的末行换行；多字段、多记录均拒绝，不截取首格。结束引号后的杂字符及未闭合引号也拒绝。该解析器供网格浏览模式使用，文本编辑器内的原生粘贴不调用它。
