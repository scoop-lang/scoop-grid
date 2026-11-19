# Scoop Grid 公开合同

本文件随实现记录可用 API；完整阶段设计见 [DESIGN.md](DESIGN.md)。公开包为 `scoop.grid`，作为普通库依赖 Scoop UI，不增加语言或 runtime 机制。

## 类型化列

`GridColumnId` 是非空字符串组成的稳定列身份，标题不参与身份。`gridColumn<Row, T>` 将取值、格式化、比较和查询字面量解析绑定到同一个 `T`；不同值类型的列通过 `GridColumn<Row>` 共同操作，不暴露动态单元格值容器。

`GridValues<T>` 定义值的类型、文字、比较和字面量解码。内置文本、Long、Double、Boolean 和 LocalDate 值描述；`nullableGridValues` 在原有类型上区分缺值和普通值。文本匹配可区分大小写或进行 ASCII 大小写折叠；非 ASCII 字符按原字符匹配，不宣称支持语言相关排序／大小写规则。数值排序不经过格式化文本，Long 保留完整整数精度。

`GridColumn` 同时提供显示 View、无须创建 View 的文字和可选数值。自定义 `cell` 覆盖显示，不改变排序、筛选、复制所依据的数据。操作列由 `gridActionColumn` 创建，不支持排序、筛选或导出，错误调用抛出 `IllegalArgumentException`。

默认文字单元格通过 `GridColumn.cell` 的可选字体、文字样式和段落参数接收 Grid 的真实主题／方向。用户自定义 View 仍使用自身配置。测量与呈现使用相同的字体，默认文字单行省略；操作列不被强制转换成 Label。

## 查询

`GridQuery` 包含稳定多列排序、AND／OR 筛选树、快速筛选和 `GridPagination`。筛选支持比较、闭区间、集合、缺值及文本包含／前缀／后缀。日期使用 `LocalDate` 语义，数值支持精确整数和浮点字面量；列入口拒绝不匹配的字面量、反向区间、重复排序及未知列。

普通比较和区间不匹配缺值。缺值可以通过 `Missing` 或集合中的 `Empty` 明确匹配。`NotEqual` 同样不包含缺值。缺值的排序位置由列的 `missingLast` 决定，在升序和降序中保持不变。排序比较相等时保持原始行次序。

快速筛选对可导出列的数据文字进行 ASCII 大小写折叠后包含匹配，任意一列匹配即保留该行。它不创建单元格 View。

`GridPagination.Disabled` 返回全部筛选后行；`Page(index, size)` 要求非负页索引、正页大小，超出末页时夹到末页，空结果归零。查询条件变动回到第一页，单独换页不会重跑排序和筛选。

## 本地状态与数据

`DataGridState<Row>` 消费不可变 `TableSource<Row>`，应用可复用 `TableRows`／`TableRecord`。来源必须履行 `TableSource` 的稳定、显式、唯一 key 与互逆索引合同；`TableRows` 已在构造时验证，不重复全量检查该事实。

状态通过 `setQuery`、`setPage`、`setPagination`、`toggleSort`、`replaceData` 和 `replaceColumns` 更新。模型在动作入口计算并发布一个完整结果，属性读取不执行查询。查询失败保持旧快照。来源、列集合和查询条件未变时复用已有顺序，页码与列外观动作不使查询失效。

`GridResult<Row>` 暴露本页 `rows`、全部筛选结果 `ordered`、`totalRows` 和 `pageCount`。`columns` 返回当前列定义，`columnState` 数组顺序就是用户的列顺序。宽度受已有 `TableColumnSize` 限制；列可以显示／隐藏、移动、设置逻辑 Start／End 冻结。设置宽度、移动和显隐不会访问行数据。实际视口冻结几何由布局批次补充。

替换列先验证新集合，保留存活列的宽度、顺序、显隐和冻结，新增列追加。查询中删除的列引用被删除；AND／OR 中删除后为空的组合被移除，不伪造恒真子句。存活列的类型合同变化后重新检查其查询，错误时整个替换不发布。选择和层级行为尚未由本文件发布。

## 文本导出与单格粘贴解析

`gridCsv(rows, columns, includeHeaders = true)` 输出 CSV 字符串，使用逗号、CRLF、标准双引号转义，每条记录以 CRLF 结束。`gridTsv(rows, columns)` 输出适合矩形复制的制表符分隔文本，行间使用 LF，不额外增加末行换行。调用者明确提供数据范围及列顺序；例如本页使用 `model.result.rows`，全部筛选结果使用 `model.result.ordered`。函数不取数、不持有文件或剪贴板、不创建 View，也不建立额外的单元格矩阵。

不允许导出的列被省略；全部列均不可导出时报告错误。可导出列必须提供数据文字，缺值由该列正常格式化。逗号／制表符、双引号、CR 和 LF 按对应格式加引号。不存在公式解析或导出为 Excel 公式的特殊分支。

`parseGridCellPaste(text)` 返回 `GridCellPaste.Value` 或带原因的 `Rejected`。允许标准引用字段、字段内部换行、转义双引号，以及一个可选的末行换行；多字段、多记录均拒绝，不截取首格。结束引号后的杂字符及未闭合引号也拒绝。该解析器供网格浏览模式使用，文本编辑器内的原生粘贴不调用它。

## 原生网格与定位

`dataGrid(state) { ... }` 创建 `DataGrid<Row>`，消费同一模型的当前页。`DataGridProps<Row>` 与 builder 提供外框宽高、固定行高／表头高、像素 overscan、可借用的 `ScrollState`／`DataGridHandle`、字体、主题及启用状态。尺寸按主题密度缩放；明确宽高受父约束限制。默认行高 48、表头高 40、外框高度 320。模型可以被多个挂载消费，但每个挂载有自己的滚动与焦点会话；一个 handle 或 ScrollState 同时只绑定一个挂载。

普通父 Element 拥有唯一滚动视口，表头与正文分别按列、按行虚拟化，每个正文行再按列虚拟化。所有条目使用本次 `LayoutInput` 中的相同列宽和滚动结果；scene 只消费自己的完整 LayoutResult。列宽复用 `TableTracks`，Auto 只测表头及声明的文字样本，不创建业务行。横向滚动只挂载可见列、冻结区和实际活动项；不为每个行列组合预建 View 或 FocusHandle。

Start／End 冻结随 RTL 转换到对应物理边。它们与中心共享同一套列宽和单元格实例。表头保持垂直固定，正文不能绘制或命中表头区域。窄窗口先保留 Start，再裁剪 End，中心剩余宽度可以为零；零面积不发布命中区域。

`GridCellAddress(row, column)` 使用来源 key 与 `GridColumnId`。`DataGridHandle.focusCell(address)` 只接受当前结果中的有效可见列及业务 key，返回请求是否接受；真实焦点必须等布局 Accepted 后落到该格的真实 FocusHandle。`focusedCell` 反映实际焦点（包括自定义内容后代），`pendingCell`／`isPending` 反映尚未完成的请求。`cancelFocus()` 只取消定位请求。目标删除、禁用、外部焦点或新请求沿原 UI 焦点路径取消旧请求，不能在迟到帧中复活。表头排序沿模型入口执行。

## 键盘浏览与单元格内控件

浏览目标是每格真实的外层焦点。左右键按物理方向移动，RTL 下反向解析逻辑列；上下键保持列身份。Home／End 到当前行的首／末可见列，Primary＋Home／End 到当前结果的首格／末格。PageUp／PageDown 按最近 Accepted 的正文高度移动，保持列；箭头与翻页在边界停住，Tab／Shift＋Tab 按行列顺序换格，越过网格首尾后交给现有外部 Tab 顺序。隐藏列不参与浏览，冻结列与中心列共用顺序。

每个自定义单元格的内容是一个真实 FocusScope。Enter／F2 从浏览目标进入其实际控件；内部 Tab 先遍历该格的控件，离开边界才换格；内部未被控件或弹层处理的 Escape 返回该格浏览目标。内容消费的箭头、文字和 IME 事件不会再触发网格导航。普通点击仍沿现有输入归属，子按钮认领的点击不会再次激活外层。

选区、自动行高和离屏列的原生 AX 动作继续沿同一生产组件实现，不因键盘浏览可用而计为完成。

## 有类型的单格编辑

`gridColumn` 的可选 `edit` 由 `gridEdit<Row, T>` 构造。编辑器工厂、相等比较、同步校验和应用提交始终保留 `T`；`GridColumnEditing<Row>` 只封装对共同列接口必要的操作，不提供动态值盒。列可用 `editable` 按记录决定是否允许编辑。

`GridEditor<T>` 返回 `GridCandidate.Value(T)` 或 `Rejected(message)`，通过 `GridEditorOptions` 接收真实焦点、字体／主题、错误、提交中状态和提交回调。内置 `GridTextEditor<T>` 复用 `TextEditorState` 与 Input／Textarea；文本、Long 和有限 Double 提供便捷工厂。自定义编辑器沿相同合同使用真实控件，组合输入由编辑器报告和处理。

每个挂载只有一个会话。Enter／F2 或 `DataGridHandle.beginEdit(address)` 进入可编辑格；焦点通过既有 LazyFocus 请求落在真实编辑器。不可编辑的交互格仍进入自己的内容焦点域。`editingCell`、`editError`、`isSubmitting` 可在 render 中观察当前会话，包括首次绑定前的读取。`commitEdit()` 返回 NoEdit／Committed／Rejected／Composing／Pending；`cancelEdit()` 显式结束草稿。

提交先解析、校验，并重新核对行 key、列定义、可编辑条件和原字段。新值相等时不调用应用。`GridChange<Row, T>` 提供当前 Row、原值和候选值，应用通过 `GridCommit<Row>.accept(source)` 安装真实不可变数据快照，或 `reject(message)` 保留草稿及错误。应用可异步保留 completion；Pending 期间禁止重复提交和新编辑。回调只能在 owner 线程使用，并且只完成原会话一次；过期回调返回 false，不改写模型。应用自己的远程副作用仍由应用管理。

双击可编辑格进入编辑，子控件已认领的点击继续由子控件处理。Enter 提交后返回该格浏览；Tab 提交后按当前记录和目标 key 导航。首尾边界沿普通 UI 父级焦点遍历继续，异步保存完成后同样兑现这一方向。网格内点击其他单元格或表头，在原输入路由的 capture 阶段先尝试提交；错误、组合输入或等待保存时拒绝这次点击，避免已执行排序或子按钮动作后再回退。组合输入未完成时不读取 preedit 作为候选。Escape 先由原生输入法／编辑器处理，未消费时取消当前草稿。文本内撤销使用原生单格历史。

焦点离开编辑格到网格外控件时尝试提交，成功后保留外部焦点；校验失败会重新显露编辑器。异步保存期间允许应用外部控件继续取得焦点，Grid 保留当前草稿和提交状态。窗口失去前台激活本身不等于更换逻辑焦点。禁用、删除与卸载先执行取消规则，不因清理引发自动保存。

数据替换保留字段未变的草稿，包括同一 Row 的其他字段更新。删除记录、隐藏目标列、替换该列定义、字段变更、禁用和卸载结束旧会话；`onEditEnd` 报告地址及原因。模型通知在实际动作时处理，因此窗口隐藏也不会让已删除记录的会话继续存活。提交成功后重新查询；原 key 不再显示时移到同列最近有效行，空结果回到网格入口。普通滚动保留实际活动编辑器且沿原视口裁剪。

这一批接入显式进入编辑、双击／失焦协调及类型化提交，并以系统拼音输入法验证真实候选、Escape 取消、选词和 Enter 提交，结束后恢复原输入源。浏览状态直接输入启动编辑、布尔／日期／枚举便捷编辑器和浏览模式单格粘贴仍需后续闭合。
