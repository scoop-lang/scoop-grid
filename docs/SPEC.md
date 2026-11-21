# Scoop Grid 公开合同

本文件随实现记录可用 API；完整阶段设计见 [DESIGN.md](DESIGN.md)。公开包为 `scoop.grid`，作为普通库依赖 Scoop UI，不增加语言或 runtime 机制。

## 类型化列

`GridColumnId` 是非空字符串组成的稳定列身份，标题不参与身份。`gridColumn<Row, T>` 将取值、格式化、比较和查询字面量解析绑定到同一个 `T`；不同值类型的列通过 `GridColumn<Row>` 共同操作，不暴露动态单元格值容器。

`GridValues<T>` 定义值的类型、文字、比较、字面量解码和 `encode` 编码。`GridValueKind.Integer` 与 `Number` 分别表示精确整数和浮点数；编码结果保持相同类型，格式化标签不参与值身份。自定义值描述应保证编码／解码往返，并让比较等价的值使用同一字面量。内置文本、Long、Double、Boolean 和 LocalDate 值描述；`nullableGridValues` 在原有类型上区分缺值和普通值。文本匹配可区分大小写或进行 ASCII 大小写折叠；非 ASCII 字符按原字符匹配，不宣称支持语言相关排序／大小写规则。数值排序不经过格式化文本，Long 保留完整整数精度。

`GridColumn` 同时提供显示 View、无须创建 View 的文字和可选数值。自定义 `cell` 覆盖显示，不改变排序、筛选、复制所依据的数据。操作列由 `gridActionColumn` 创建，不支持排序、筛选或导出，错误调用抛出 `IllegalArgumentException`。

默认文字单元格通过 `GridColumn.cell` 的可选字体、文字样式和段落参数接收 Grid 的真实主题／方向。用户自定义 View 仍使用自身配置。测量与呈现使用相同的字体，默认文字单行省略；被指定为自动行高贡献列时允许按实际列宽换行。操作列不被强制转换成 Label。

## 查询

`GridQuery` 包含稳定多列排序、AND／OR 筛选树、快速筛选和 `GridPagination`。筛选支持比较、闭区间、集合、缺值及文本包含／前缀／后缀。日期使用 `LocalDate` 语义，数值支持精确整数和浮点字面量；列入口拒绝不匹配的字面量、反向区间、重复排序及未知列。

普通比较和区间不匹配缺值。缺值可以通过 `Missing` 或集合中的 `Empty` 明确匹配。`NotEqual` 同样不包含缺值。缺值的排序位置由列的 `missingLast` 决定，在升序和降序中保持不变。排序比较相等时保持原始行次序。

快速筛选对可导出列的数据文字进行 ASCII 大小写折叠后包含匹配，任意一列匹配即保留该行。它不创建单元格 View。

`GridPagination.Disabled` 返回全部筛选后行；`Page(index, size)` 要求非负页索引、正页大小，超出末页时夹到末页，空结果归零。查询条件变动回到第一页，单独换页不会重跑排序和筛选。

`gridQuickFilter(state) { ... }` 组合现有 Input 与按钮，输入保存在本次挂载的文本草稿中；Enter 或“应用”把已提交文字一次写入查询，“清除”同时清空快速筛选和草稿。未结束的输入法组合不应用，输入本身不触发全量筛选。应用主动更新快速筛选或替换模型时以新的应用值重置草稿；只有排序、分页或数据变化时保留草稿。

`gridPager(state) { ... }` 组合现有 Select 与 Pagination，显示筛选结果条数、当前页和总页数。页大小列表要求正数且无重复，默认 25／50／100；当前页大小即使不在列表中也按实际值显示。“全部”明确设置 `GridPagination.Disabled`，同时移除翻页按钮，仍显示完整结果条数和页大小选择；再次选择页大小从第一页开始。空结果显示零条，翻页按钮不可用。

查询控件的 `labels` 分别接收 `GridQuickFilterLabels` 和 `GridPagerLabels`，可配置占位文字、按钮、无障碍名称、页大小、页码和结果数文案，默认保留中文。计数和页码通过明确的格式化回调提供，不从显示文字反向解析逻辑值。更新文案保留现有输入草稿、真实焦点、查询与分页状态，也不产生查询通知；选择项的稳定 key、`GridPagination` 值和控件 automation id 独立于文案。

两个查询控件均可通过 builder 的 `handle` 关联对应挂载，先处理该网格的单元格编辑，再更新查询。非法草稿、组合输入或等待保存时不应用本次动作，保存结束后不会补执行已拒绝的操作；用户可在结束后再次操作。每次成功只设置一个完整查询，保留其他查询字段，并按模型合同收敛页码。未关联 handle 时仅操作模型，适用于无编辑器的表格或独立查询界面。禁用控件不修改查询；字体、主题和真实焦点复用现有组件。

`gridFilterPanel(state) { ... }` 用现有 Select、Input、DatePicker、Checkbox、ScrollArea 和 VirtualList 编辑类型化筛选草稿。条件组可嵌套 AND／OR；支持文本包含／前后缀、比较、闭区间、缺值和集合。整数不经过 Double，日期按 ISO 日期解析，非法值、反向区间、失效列和空的嵌套条件组给出错误并保留草稿。根没有条件时表示不过滤；空集合表示不匹配任何值。`referenceDate` 指定空日期编辑器打开日历时的参考日；默认采用面板创建时的 UTC 日期，应用可传入本地参考日，实际条件只保存 `LocalDate`。

点击“应用筛选”才发布一次完整查询，保留排序、快速筛选和分页配置并回到第一页；“清除筛选”应用 All，“还原草稿”只恢复当前模型条件。可选 handle 使用同一单格编辑门控。条件输入的组合尚未结束、单元格未能提交或正在保存时，不改变查询，也不在之后补执行旧操作。应用主动替换筛选或模型时重置草稿；其他查询字段和数据更新保留草稿。列的显隐不删除条件，隐藏列仍可编辑筛选。

`DataGridState.filterValues(columnId)` 是明确的数据操作，按完整本地来源派生 `GridFilterValues.values`（每项为 `GridFilterValue(key, label)`）。key 是真实 `GridLiteral`，重复标签不合并不同值，缺值和空字符串分别保留。只读取该列数据，不构造单元格 View；按值首次出现顺序去重。数值候选要求有限值。结果按来源与列定义复用，查询、分页、调宽和显隐不会清除它，成功替换来源或列定义后失效。构造模型、呈现面板、打开条件菜单和语义查询都不隐式扫描来源。

集合条件由“加载候选”显式取得该快照；可搜索候选标签、选中当前列表或清空选择，列表沿已有 VirtualList 按视口构造。来源或列定义变化后提示重新加载，旧候选不冒充当前快照，已选字面量继续保留在草稿中。候选来自完整本地来源，与当前筛选结果和页码无关；外部结果模式另按完整设计提供候选，不用已加载页冒充全体值。

筛选面板的 `labels: GridFilterLabels` 配置按钮、条件组与条件名称、比较方式、占位文字、布尔选项、候选状态、缺值／空字符串提示、输入错误和无障碍名称，默认中文。含路径、列名与计数的文字使用明确参数的格式化回调。更换 labels 保留草稿、输入焦点、候选快照和已选值，不执行查询或重新加载候选；下次显式搜索使用当时的候选显示文字。运算符、组连接、候选键和控件 automation id 均不使用显示文字作为身份。`error` 回调供应用格式化面板收到的错误消息，默认原样显示，不改变错误所属操作或查询失败原子性。

## 类型化聚合

`gridColumn(..., aggregations = [...])` 声明该列允许的 `GridAggregation<T>`。`GridAggregateId` 是非空稳定 id，名称可本地化且不参与身份。列内聚合 id 不得重复；纯操作列默认不提供聚合。`GridQuery.aggregations` 保存有序的 `GridAggregationSelection(column, operation)`，当前每列至多选一个操作。模型入口拒绝未知列／操作和重复度量列；`setAggregation(column, operation)` 替换该列选择，传 None 清除。

`gridAggregation<T, A, R>` 显式绑定输入、累加器和输出类型，接受 seed／add／finish、结果格式化／比较及可选的精确数值转换；累加器与原始 R 结果均留在泛型实现中。seed 为每组提供独立初值，应用保持完成结果不可变，不使用动态值容器。缺值在列绑定处跳过，finish 接收非缺值数量；空结果默认缺值，可显式提供空结果值。真实算术异常转换为该项的 `GridAggregateDisplay.Failed`；内置数值 min／max 通过列的 encode 检查数值有效性，encode 拒绝的数值输入也作为聚合错误，不要求可选的 number 投影。其他应用异常仍向动作调用方传播且不发布半份状态。格式化文字只用于显示。

内置 count／min／max 适用于明确类型的值；Long、Double 和 BigDecimal 提供 sum／average。count 返回 Long，统计非缺值，和 `result.totalRows` 的记录数分开。全缺值时 count 为零，其他内置操作为缺值。Long sum 用 BigInteger 累加，完成时检查 Long 范围，不经 Double；Long average 输出 Double，使用 Decimal128 中间除法。Double sum 检查非有限输入及每步溢出，average 用十进制累加和 Decimal128 除法后输出 Double，避免有限平均值因中间浮点和溢出而失败。BigDecimal average 必须显式给出 scale 与 roundingMode。`nullableGridAggregation` 将相同操作绑定到可缺值的输入。

`result.aggregates.total(column)` 返回该项显示结果（Value／Missing／Failed），未配置该列时返回 None。`numericTotal(column)` 只返回已成功且有数值转换的精确 BigDecimal。结果内部保留真实类型与比较操作，显示字符串不用于排序。聚合始终消费整个筛选结果；切页、列宽、显隐、固定行和业务选择均复用既有聚合。改变排序只改变行序，保留同一筛选集的聚合结果；数据、筛选、快速筛选、度量或列定义变化时重新计算。

选择聚合沿查询动作通知并重置页码，列替换清理已移除或不再允许的操作；视图保存和恢复包含聚合选择，恢复报告具体失效项。列面板只为允许聚合的列显示选择器，使用现有编辑提交门控；非法草稿或等待保存时不切换聚合。`gridAggregationSummary` 显示筛选记录数与各列总计，使用现有主题、字体和显式 Labels，不读取记录或在绘制中启动计算。分组行及两种层级的小计复用相同的类型化结果。

## 本地行分组

类型化列通过 `gridColumn(..., groupable = true)` 明确允许分组；组键来自同一 `GridValues.encode`，标签来自 format，同级比较使用原始 T 的 compare。缺值统一使用 `GridLiteral.Empty`，不与空字符串、零或同名标签混同。动作列不参与分组。

`GridQuery.grouping` 按维度顺序保存列 id；重复、未知或不允许分组的列在查询发布前拒绝。`GridGroupPath` 由有序 `GridGroupPart(column, value)` 组成，作为 `GridRowKey.Group(path)` 的稳定身份。路径包含真实类型及完整值，内部 ViewKey 编码采用类型标记和长度前缀；排序、展开、格式化标签或分页都不改变组身份。

本地流水线先筛选业务记录，再构造组与类型化聚合，排序同级组及组内记录，按根组分页，最后按展开状态生成逻辑呈现。`GridQuery.sorting` 排序叶记录；`groupSorting` 的 `GridGroupSort(column, by, direction)` 为指定分组维度提供组排序，by 为 Value 或 Aggregate(metricColumn)。同一维度可按多个不同目标依次比较；没有配置时按该维度原值升序，有效值相等后保留来源顺序。维度缺值的位置由列的 `missingLast` 固定；聚合缺值及错误保持在有效值之后，不随降序翻转，也不按显示文字比较。

`GridRow.Group`／`GridRowInfo.Group` 保存组路径、标签、成员数和该组聚合；没有伪造的业务 Row。`GridQuery.groupTotals` 使用独立的 `GridTotals` 配置，默认隐藏、标签为“小计”；Before／After 分别放在已展开组的子项之前／之后。组内小计使用 `GridTotalKey.Group(path)`，与全筛选集总计、业务 key 分域。所有组和小计复用同一批度量结果，隐藏、分页及展开不重算聚合。

`GridExpandedRows(defaultExpanded = false, exceptions = [])` 保存普通视图数据，exceptions 为与默认值相反的逻辑行 key。DataGridState 的 `expandedRows`、`isExpanded`、`setExpanded` 和 `setExpandedRows` 使用稳定身份；仅展开变化复用分组、排序、当前页业务快照与聚合，不重新读取业务值；自定义可选条件的页内资格计数也沿相同成员快照复用。筛选暂时隐藏一个组时保留其展开选择；更换分组维度清理不再匹配维度路径的记录。视图快照保存展开数据，恢复时报告不适用的配置。

分组结果的 `rootCount` 为根组数，`pageUnit` 为 Roots；平面结果为业务行数与 Records。pageSize 只计根项，展开后代和小计留在其根页。`pageRows` 包含所选根页内全部匹配业务成员，折叠不改变分页全选范围；`ordered` 包含全部筛选业务记录，`totalRows` 仍为匹配记录数。固定业务行继续保持唯一身份，不改变根计数或聚合成员。

`GridRowSource.hierarchyAt(index)` 返回可选 `GridRowHierarchy(level, parent, expanded)`，只读取元数据。平面行没有层级；组声明深度及展开状态，业务成员和小计声明其父组与深度。来源组合、固定及切片保留这份描述，系统语义不通过构造 View 推测层级。

组行只读，使用现有单元格布局和连续矩形操作。组标签优先放在对应分组列，其次是首个没有度量的可见列；仅有度量列时在首列同时显示组标签和度量。Enter／F2 从组标签格进入真实展开按钮，按钮自身的 Enter／Space、点击与原生 expanded 动作进入同一编辑门控，普通方向键保留二维导航，Alt＋Right／Left 也可明确展开／收起当前层级行。收起含当前编辑或焦点的后代前先完成编辑门控，再将焦点恢复到有效父组。组行不作为独立业务选择对象；其 Checkbox 和明确的组选择操作按整个已知匹配成员集计算三态，折叠不改变成员，可选性规则仍作用于实际业务记录。

`groupSelectableRows(path)` 和 `groupRowSelection(path)` 只在 Multiple 模式统计本次筛选的合格成员；`selectGroupRows(path, value)` 修改这些业务 key，保留其他组与暂不匹配筛选的已有选择。不存在的组返回 false；Single／Disabled 模式不提供组选择。挂载的 `handle.setExpanded(key, value)` 与 `handle.selectGroupRows(path, value)` 返回 `GridRowActionResult`，旧语义快照或已失效目标不能操作新结果。

列面板对允许分组的当前列提供“不分组／第 N 级分组”、同级组的值／度量排序和方向，以及分组小计位置；调整层级同时调整维度顺序。面板每个层级提供一个排序依据，明确修改该项会替换该层级的排序配置；模型 API 仍允许多个依次比较的目标。移除维度或度量同步删除失效组排序，不修改业务列排序。`GridColumnsLabels.grouping` 的 `GridGroupingLabels` 配置文案，`GridLabels` 配置展开、折叠及组选择名称。`gridPager` 同时显示根组数和业务记录数，页大小明确使用“组／页”；`GridPagerLabels` 的 rootSize／rootSizeName／roots／rootStatus 可单独本地化。

复制、查找、统计与 CSV 使用同一逻辑值描述；业务回调只接收真实 Row。Records 导出业务记录；Displayed 导出按当前展开状态排列的组、业务行与小计，可独立排除组行及总计。AllFiltered 取消根分页但保留当前展开配置；SelectedRows 始终导出业务选择。

## 本地树数据

`DataGridState(..., treeData = Some(GridTreeData(parentKey, column)))` 使用现有完整 `TableSource<Row>` 和 `(Row) -> ViewKey?` 父引用；None 表示根，column 是可选的层级显示列，默认使用首个可见列。父引用只依赖当前不可变记录。接入来源时一次检查显式且唯一的业务 key、缺失父引用和实际父环；数据或父引用定义不变时，筛选、排序、分页、展开、列状态和选择复用已验证拓扑。深度遍历与路径保留使用迭代处理，不依赖调用栈深度。

树数据与行分组互斥。`setTreeData(value)` 显式启用、替换或关闭树定义；启用时当前 grouping 必须为空，树模式中的 setGrouping 拒绝非空维度。切换拓扑回到第一页并清除旧矩形，准备失败保留原状态。`replaceData` 更新父引用和记录，删除已失效的展开 key；更改显示列或隐藏它时，层级控件回退到首个可见列。树定义包含应用回调，不序列化进视图快照；恢复视图时使用当前定义，并报告不相容的分组或展开项。

筛选逐条判断原始记录，只保留匹配节点及连接它们所必需的祖先。匹配父节点不会自动带入不匹配的后代。`GridRowHierarchy.contextOnly` 标记仅因路径保留的祖先；`isContextRow(key)` 可直接查询。它们继续显示自己的真实业务字段，允许普通单格编辑，但不可作为本次筛选的业务选择对象。当前页全选、三态与聚合只计算实际匹配节点；筛选前保存的全局选择仍保留，SelectedRows 导出继续按保存的业务 key 工作。

`GridQuery.sorting` 在每个兄弟集合内稳定排序，根也使用相同比较；相同值保持来源顺序，缺值沿列规则处理。`expandedRows` 使用 `GridRowKey.Data(key)` 保存展开选择，默认折叠；筛选暂时隐藏节点不会清除其展开状态。业务节点的层级、父 key、当前可展开状态及 contextOnly 可通过 `hierarchyAt` 读取，不构造 Row 或 View。叶节点没有 expanded 语义，明确展开叶或已删除节点返回 false。

树结果的 `pageUnit` 为 TreeRoots，`rootCount` 为保留的根数，pageSize 表示根节点数；分页界面明确显示“根／页”。所选根的后代与小计留在同一页。`pageRows` 包含当前根页中所有实际匹配记录，`ordered` 包含全部匹配记录，二者不受折叠影响且不包含仅作路径的祖先；`totalRows` 统计匹配记录。呈现结果包含必要上下文。固定业务记录从正文移出后仍保留原层级，只出现一次；固定一个折叠分支中的记录也保留其原父 key，固定与折叠不改根页及聚合成员。

树节点自身字段不被后代聚合覆盖。`treeAggregations(key)` 返回该节点子树中实际匹配记录的类型化聚合，包含节点自身（仅当它匹配）；未知或本次筛选未保留的节点返回 None。全筛选总计仍只计算每条匹配记录一次。`GridQuery.treeTotals` 明确启用已展开非叶节点的小计，默认 Hidden、标签为“子树小计”，Before 放在父记录之后、子项之前，After 放在该分支后。`GridTotalKey.Tree(key)` 与业务、分组及全筛选总计身份分域。小计复用已有类型化结果，排序、展开、分页及固定不重读聚合输入。

树的展开按钮、按钮 Enter／Space 及系统 expanded 动作共用分组的编辑门控。浏览格的 Alt＋Right 展开、Alt＋Left 收起；只读层级格的 Enter／F2 进入真实控件，可编辑格继续进入编辑器。展开控件位于真实业务内容前，深度缩进和路径上下文提示沿同一单元格显示；普通方向键仍用于二维导航。收起使当前后代格消失时，完成编辑后将焦点恢复到父节点同列。层级列可照常编辑，进入编辑后使用原类型化编辑器。`GridLabels` 的 expandNode／collapseNode／contextRow 与 `GridPagerLabels` 的 treeRootSize／treeRootSizeName／treeRoots／treeRootStatus 可配置。

CSV 的 Records 范围仅包含匹配业务记录，Displayed 保留实际展开、必要路径祖先和已启用小计；includeTotals 控制两种层级的小计及全筛选总计，includeGroups 只控制分组合成的组行。AllFiltered 取消根分页但保留展开状态。复制、查找、数值统计和单格提交继续使用节点自身字段，路径提示不改写业务文本。

## 本地状态与数据

`GridRowKey` 区分 `Data(ViewKey)`、`Group(GridGroupPath)` 与 `Total(GridTotalKey)`；全筛选集总计使用 `GridTotalKey.AllFiltered`，组小计使用 `GridTotalKey.Group(path)`，子树小计使用 `GridTotalKey.Tree(key)`。`GridCellAddress.row` 和 `GridReadingPosition.row` 保存该类型化身份，接收业务 `ViewKey` 的构造器等价于显式构造 Data。业务选择、固定行和应用提交仍使用原业务 key。底层 ViewKey 编码将文本业务 key 与结果行身份分域，不能将编码后的 ViewKey 再当业务 key 使用。

`GridResult.rows` 为 `GridRowSource<Row>`，其 `rowAt` 返回完整的 `GridRow.Data(row, key)`、`GridRow.Group(group)` 或 `GridRow.Total(total)`。`infoAt` 只返回同种身份及展示元数据，不读取 Row；`rowKeyAt` 和 `indexOfKey(GridRowKey)` 用于逻辑地址定位。普通 `keyAt`／`indexOfKey(ViewKey)` 是 UI 虚拟化使用的编码身份。无论结果多大，平面来源包装、分页、固定行和追加总计都不为全部记录分配逐行描述。

`GridQuery.totals` 使用 `GridTotals(placement, label)`，placement 为 Hidden／Before／After，缺省 Hidden；label 缺省“总计”。总计位于正文业务行之前或之后，处于顶部／底部固定行之间，不占 pageSize，不增加 totalRows，空结果仍可显示一条总计。它始终读取同一份全筛选集的类型化聚合，数值列不因总计文字而丢失结果。首个可导出且没有度量的可见列显示 label；全部可见列都是度量时只显示各项值，行的无障碍名称仍提供 label。未配置的其他列为空，Missing 为空，Failed 显示错误原因并保留失败状态。

总计使用普通单元格布局、键盘定位、矩形、查找、复制和精确数值统计；不调用业务 Row 的 View、跨度、行高、可选性或编辑回调，不提供业务勾选、固定和编辑动作。无障碍行通过 selectable=false 明确退出集合选择，同时保留阅读和真实焦点；系统不公布该行的选择状态与 setter。普通行和总计共享一个挂载及会话，不伪造业务记录。切换总计位置／文字保留当前页并复用查询及聚合；位置变化清除原矩形，仅改 label 保留矩形；视图快照保存总计配置。

`DataGridState<Row>` 消费不可变 `TableSource<Row>`，应用可复用 `TableRows`／`TableRecord`。来源必须履行 `TableSource` 的稳定、显式、唯一 key 与互逆索引合同；`TableRows` 已在构造时验证，不重复全量检查该事实。

状态通过 `setQuery`、`setPage`、`setPagination`、`toggleSort`、`replaceData` 和 `replaceColumns` 更新。模型在动作入口计算并发布一个完整结果，属性读取不执行查询。查询失败保持旧快照。来源、列集合和查询条件未变时复用已有顺序，页码与列外观动作不使查询失效。

`GridResult<Row>` 暴露按 Top／Body／Bottom 排列的当前呈现 `rows`、原始查询分页 `pageRows`、全部筛选结果 `ordered`、`totalRows` 和 `pageCount`。`pageRows` 与 `ordered` 仍为业务 `TableSource<Row>`，`rows` 为逻辑行来源；`topCount`、`bodyCount`、`bottomCount` 描述呈现序列的三个连续区域。`columns` 返回当前列定义，`columnState` 数组记录用户顺序；实际呈现按 Start、普通、End 区域排列，各区域内保留该顺序。宽度受已有 `TableColumnSize` 限制；列可以显示／隐藏、移动、设置逻辑 Start／End 冻结。设置宽度、移动和显隐不会访问行数据。

`setColumnState` 更新一列，`setColumnStates` 一次安装完整列状态数组；后者必须恰好包含当前所有列，每列一次，数组顺序即新的用户顺序。全部引用与宽度成功解析后才发布，失败保留原数组；内容完全相同的更新复用原数组。两者均保留查询和查询结果。直接模型操作可设置超出当前窗口的冻结宽度，布局仍按既有窄窗口规则裁剪。

替换列先验证新集合，保留存活列的宽度、顺序、显隐和冻结，新增列追加。查询中删除的列引用被删除；AND／OR 中删除后为空的组合被移除，不伪造恒真子句。存活列的类型合同变化后重新检查其查询，错误时整个替换不发布。层级行为尚未由本文件发布。

## 视图状态保存与恢复

`model.saveViewState()` 返回 `GridViewState`，保存当前列顺序／显隐／逻辑宽度／冻结、完整查询、固定行、业务行选择、展开配置和唯一矩形。它只含普通数据，没有来源、Row、View、回调、编辑草稿或在途请求；应用负责持久化。可显式附带 `readingPosition` 和 `focusedCell`。挂载后的 `handle.saveViewState(includePosition = true, includeFocus = true)` 可取得最近 Accepted 的阅读锚点及最近成功单元格，未挂载返回 None。

`model.restoreViewState(value)` 在当前来源与列定义下准备完整结果，一次发布后才通知模型观察者、查询和选择回调。保存页码按恢复后的结果夹取，不因恢复了筛选而强制回到首页；相同查询复用已有顺序。计算或数据读取失败抛出异常，保留原模型。准备期间应用主动更新了模型时不覆盖应用的新状态。

返回的 `GridRestoreReport.issues` 使用 `GridStatePart` 指明未采用或被调整的状态项。未知、重复列及排序项跳过；新增列保留当前设置并追加；无效宽度保留当前宽度，有效宽度受当前最小／最大限制。不允许拆散当前列组的顺序整体退回当前顺序，其余列属性仍恢复。已删除列、不可筛选列和与当前类型不相容的条件从筛选树移除，空组移除，根无条件时为 All。固定行和业务选择按当前完整来源清理，选择仍遵守禁用／单选及记录资格；单选采用首个有效 key，其余逐项报告。

矩形只有在保存的可见逻辑列序与恢复后完全一致、两个端点均在恢复后的呈现结果中时才恢复。`GridReadingPosition(row, rowOffset, horizontalOffset)` 保存正文行 key 与非负有限的逻辑偏移；已删除、被筛选、位于其他页或变成固定行的阅读锚点不恢复。最近单元格要求当前呈现行和可见列均有效；两者的失效分别报告。

`handle.restoreViewState(value, restoreFocus = false)` 先通过当前编辑门控，返回 `GridRestoreResult.Restored(report)` 或 `Rejected(message)`。组合输入、非法草稿、等待保存、禁用和卸载拒绝，保存完成后不重放。有效阅读位置在同一 Accepted 布局路径按真实行高夹取，新的滚动、查询或模型替换取消旧位置。默认只保存最近地址，不抢焦点；显式 `restoreFocus = true` 在恢复布局后通过既有按 key 定位请求焦点，必要时进一步显露目标。位置完成或失效后结束，不持续请求帧。

## 业务行选择

`DataGridState(..., rowSelection = GridRowSelectionMode.Single／Multiple)` 启用业务行选择，缺省 Disabled。可选 `selectable: (Row) -> Boolean` 只依赖当前不可变记录；没有该回调表示所有业务记录可选。选择保存稳定 key，与真实焦点及单元格范围独立。`selectedRowKeys`、`isRowSelected(key)` 可观察当前选择，`onSelectionChange` 只在集合确实改变时通知。

`setRowSelected(key, value, extend = false)` 返回是否接受操作；Single 选中一项时清理旧项。Multiple 的 extend 从最近普通行选择的锚点按当前呈现顺序扩展，跳过不可选记录；锚点已不在当前结果时按普通单行操作处理。也可用 `selectRowRange(anchor, end, value)` 明确选择或取消一个业务行范围。`setSelectedRows(keys)` 原子安装完整集合，拒绝重复、未知、不可选 key 或与模式不符的数量；`clearRowSelection()` 清空。

`selectPageRows(value)` 只用于 Multiple，目标是 `result.pageRows` 的可选记录，不包括额外显示的页外固定行。`pageRowSelection` 返回现有 CheckState 三态，`pageSelectableRows` 是对应数量。全量无条件可选时从页计数和已选 key 得到状态；有自定义条件时按不可变页快照复用一次资格计数，不在滚动或普通重绘时重新扫描。

过滤、排序、分页和固定行变化保留业务选择；完整本地来源删除记录或将其变为不可选时清理对应 key。选择动作不重新运行查询，也不构造离屏 View。业务模型方法供应用主动更新；挂载的 `DataGridHandle.setRowSelected`、`selectPageRows` 和 `clearRowSelection` 返回 GridRowActionResult，拒绝未挂载或禁用的操作。

默认在首个可见数据列的内容前组合真实 Checkbox，Multiple 同列的叶表头提供“选择当前页”三态控件；`selectionCheckboxes = false` 隐藏这些配套控件，保留选择事实、选中行底色和原生选择能力。Shift＋Checkbox 从选择锚点扩展，浏览格的 Shift＋Space 切换当前业务行；自动重复不反复切换，也不把该空格交给单元格编辑。Checkbox 的输入归属优先，点击不会重复触发单元格或表头动作；普通编辑提交规则仍适用。原生 Table 的选择快照只报告当前结果中的已选行，离屏 SetSelected 与 Checkbox 共用当前模型动作，不要求先挂载行。

## 单矩形数据范围与复制文字

`GridCellRange(anchor, end)` 保存两个 `GridCellAddress`，行 key 必须显式。`DataGridState.cellRange` 表示唯一矩形；`setCellRange(value)` 安装或清空范围，端点不在当前结果行或可见列中时返回 false，旧范围保持不变。`clearCellRange()` 清空，`isCellInRange(address)` 查询当前逻辑格是否在范围内。范围与业务行选择和实际焦点独立；设置范围不读取 Row、不执行查询，也不要求对应 View 已挂载。

行顺序为当前结果的 Top／Body／Bottom，列顺序为 Start／普通／End 各区的可见逻辑顺序，RTL 不反转复制顺序。反向锚点同样解释为连续矩形。排序、筛选、分页或固定行配置变化清除范围；可见列顺序／显隐变化同样清除。仅列宽、冻结但不改变逻辑列序、表头名称或值格式更新时保留；完整来源替换仅在有效查询和所有呈现行 key 顺序未变时保留。后一判断只在有活动矩形时比较 key，不读取 Row，且在发布新来源前完成；数据或列更新失败不会改变旧范围。

`copyText(fallback = None, includeHeaders = false)` 优先复制当前矩形，没有范围时使用调用方提供的单格地址；没有有效目标时返回 None。调用开始时捕获同一结果、逻辑列序和列定义快照，后续格式化不混入新的查询或列配置。输出 TSV，不建立 View；包含表头是显式选项，操作列以及 `exportable = false` 的列输出空字段并保留其位置。含制表符、换行或双引号的字段按双引号包裹和加倍，Unicode 与 Long 的原始格式化精度保留；末尾不额外附加记录终止符。跨列显示仍按各逻辑列的真实值复制。

普通单元格点击建立单格范围并聚焦；Shift＋点击从原范围锚点扩展，没有范围时从点击前的活动格扩展。Shift＋方向键、Home／End 和 PageUp／PageDown 同样扩展唯一范围，并显露端点；Primary＋Shift＋Home／End 使用当前结果边界。普通导航清除范围，Shift＋Tab 仍是反向导航。Escape 在浏览格清除矩形；编辑器、输入法和内部控件先处理自己的操作。子控件已认领的点击不会建立矩形，业务行 Checkbox 与矩形独立。范围按实际挂载格绘制底色和边界，冻结区共享逻辑范围，离屏已选格不会因此常驻。

`DataGridHandle.cellRange` 读取当前挂载的范围，`setCellRange(value)`／`clearCellRange()` 返回是否接受，禁用、未挂载或存在编辑会话时拒绝；接受后不隐式滚动或抢焦点。浏览格的系统 Copy／平台主修饰键＋C 调用 `copyCells(fallback = None, includeHeaders = false)`，优先当前矩形，否则使用显式 fallback 或当前活动格。完整文字生成后才一次写入系统剪贴板；失败保留原内容并返回 `GridCopyResult.Rejected(message)`，成功返回 `Copied`。builder 的 `onCopyResult` 接收操作结果。真实编辑器获得焦点时继续处理自身文本复制；Grid 不提供选区剪切、批量 Delete、矩形粘贴或跨格撤销。

正文鼠标左键拖动超过 6 个密度单位后进入单矩形选择，未超过阈值仍按点击处理。普通拖动从按下格开始；Shift 拖动沿用按下时的范围锚点，没有范围时使用原活动格。Ctrl／Command 不建立第二个范围。只有直接命中浏览格的按下可开始拖选，按钮、复选框和真实编辑器保留自己的输入归属。`touchCellSelection` 默认 `false`，Touch／Pen 保持普通滚动；显式设为 `true` 后，直接命中正文格的单触点可拖选。

拖选使用最近 Accepted 的列位置与行高索引，支持 RTL、固定行、冻结列和跨列显示的锚格。拖动中保持来源格的输入认领，释放后聚焦最后端点；选区不会使其余离屏格常驻。指针进入中心列区左右边缘或正文行区上下边缘时，沿现有 ScrollState 和呈现帧时钟滚动并更新端点；固定区域仅作为选择目标，不触发相应轴的中心滚动。指针移出网格时保留最后范围且停止边缘滚动。

开始前执行既有编辑门控；非法输入、组合输入或等待保存时拒绝，也不在保存完成后重放旧手势。Escape 结束拖动并清除范围；失焦、第二触点、输入取消、禁用、关闭、几何失效，以及模型／结果来源／列配置／主题布局配置／触摸选择模式变化结束手势，保留仍有效的最后范围。应用更新范围时结束旧手势，不覆盖应用结果。结束、离开边缘或抵达滚动边界后停止请求动画帧。

## 上下文菜单

DataGrid 的正文、列头与列组复用现有 ContextMenu、Menu、Overlay 和长按能力。右键、ContextMenu 键／Shift＋F10 和长按打开同一菜单；真实编辑器保留自己的文字菜单。`contextMenus = None` 关闭网格菜单，`GridMenuOptions` 配置宽度、`GridMenuLabels` 文案以及 `(target, command, result)` 回调。目标使用稳定 `GridMenuTarget` 行列／列组身份，命令身份与显示文字分开。

列菜单提供升／降序、清除该列排序、同一区域前移／后移、Start／End 冻结与解除、隐藏、恢复声明宽度、适应可见内容及适应视口。排序调整保留其他列的排序及优先级，清除仅移除当前列。列组菜单前移／后移整个逻辑组；边界上无可移动目标时不提供对应动作。正文菜单按当前目标提供复制、含表头复制、清除矩形、可编辑格编辑、业务行选择／取消和顶部／底部固定／解除。复制优先使用现有矩形，否则使用右键目标格，不依赖弹层打开后的焦点。

打开与执行菜单均遵守既有编辑门控，未完成的组合输入、非法草稿或等待保存拒绝操作；没有迟到重放。每次执行按当前模型重新检查目标和可用命令，再调用同一列、选择、编辑或复制入口。禁用、删除目标或更换模型使旧菜单失效，重新启用或切回原模型不会自动重开；虚拟回收沿原 Overlay 生命周期关闭菜单。失败保留菜单并显示说明，成功关闭；`GridMenuResult.Sizing(request)` 表示已接受内容测量，最终结果通过原 `GridColumnFit.result` 读取。

菜单、查找、状态栏和面板的 Labels 均可通过 `error(message)` 格式化呈现中的错误；原操作结果与应用回调不被改写。业务列名、Choice 标签和数据格式继续由相应列／应用配置提供。

## 状态栏与矩形数值统计

`model.rangeStatistics()` 从同一捕获结果、逻辑列序与唯一矩形读取数据，无选区返回 None。`GridRangeStatistics` 包含 `range`、`rowCount`、`columnCount`、数值 `count`、`sum`、`minimum`、`maximum` 和 `average`。只读取范围中的行，每行一次，不构造 View；固定区连续，跨列显示仍按真实逻辑字段统计，缺值和非数值不参与。已知空数值集合的 count／sum 为零，最值与平均值为 None；读取或数值转换失败抛出异常，不返回部分统计或伪造零值。

`GridColumn.numericValue(row)` 提供可统计的 `BigDecimal` 值，默认使用已有 `number(row)` 的有限 Double；内置类型化整数直接从 Long 转换，保持超过 2^53 的整数及累加结果精确，浮点使用 `BigDecimal.fromDouble` 的最短十进制表示。它不调用 formatter。`count` 为 `BigInteger`，求和与比较使用精确十进制运算，平均值按 `MathContext.Decimal128`（34 位有效数字、HalfEven）计算。这是只读数据摘要，不引入表达式、公式或计算列。

`gridStatusBar(model) { ... }` 显示结果条数、业务选择条数和“统计选区”入口。明确点击才计算当前矩形，呈现、滚动和持续拖选本身不扫描数据。结果按捕获来源、列定义、可见逻辑列序和范围复用；数据或范围变化后旧统计不再显示，需要再次计算。计算回调导致模型变化时不展示旧结果。无选区或禁用时按钮不可用。`labels` 配置文案及结果格式，`showStatistics` 可关闭统计入口，`content` 可附加应用状态 View；字体、主题和按钮焦点复用现有 UI。

## 列操作与工具面板

`DataGridState` 的可选 `headers` 声明多级列树：`GridHeaderNode.Column(columnId)` 引用现有列，`Group(groupId, title, children)` 声明一个非空组。`GridColumnGroupId` 是非空稳定字符串，与列 ID 分属不同身份域。树必须恰好包含所有列，每列一次；组 ID 在整棵树内唯一。省略时为平面表头，初始顺序按树的叶节点顺序。标题不参与身份，隐藏列仍属于原组。

`headers` 返回逻辑定义，实际同级顺序由完整 `columnState` 表示。每个组的全部后代在完整列状态中必须连续，完整状态更新拒绝拆散组。`moveColumn` 只在其直接父组内移动；`moveColumnGroup(id, index)` 一次移动整组全部后代，索引表示移动后第一片叶在完整列状态中的位置。两个入口均要求同级边界，不能把成员移入另一组，也不修改冻结位置。应用通过 `replaceColumns(values, headers = Some(tree))` 明确改组关系；新树同时给出顺序，存活列的宽度、显隐及冻结继续保留。未传新树时保留存活列的原组关系和顺序，移除空组，新增列追加到根。

挂载的同名 `DataGridHandle.moveColumnGroup` 使用与单列相同的编辑门控。表头按可见树深度分层，`headerHeight` 表示每层高度，浅层叶表头占满剩余层。组按 Start／普通／End 分成最多三个视觉片段，共用一个逻辑身份和成员集合。片段及叶表头保持同一惰性身份域，只为当前可见列的祖先和实际活动项创建 View；隐藏全部后代的组不显示。组标题不参与单列内容测宽。

组片段和叶表头发布真实层级位置及行列跨度。叶表头通过 `columnHeaders` 关联同片段内由外到内的祖先；正文单元格在祖先之后关联自己的叶表头。关系只指向真实挂载节点，沿 `SemanticsReference` 的绑定和卸载更新，不因读取关系而创建离屏表头。横向滚动时组标题保持在其可见片段内，取得焦点使用该可见范围，避免宽组被自动对齐到起点；完全离屏但因活动状态保留的组仍可按完整几何显露。跨冻结片段不共享原生节点。

叶表头拖动只能落到同父节点的边界；拖动组标题移动整个逻辑组，包括隐藏列和其他冻结片段。拖动仍在起始冻结区域内解析落点，跨区域取消；同级目标的逻辑前／后半边决定插到整个目标之前／之后。列工具显示所选列的祖先组，并提供整组前移／后移，键盘和原生无障碍用户使用同一模型动作。组定义替换取消在途拖动，已有数据、查询和仍存活的单元格保持原有合同。

`DataGridHandle.setColumnState`、`moveColumn` 和 `fitColumns` 是当前挂载的用户操作入口，返回 `GridColumnActionResult.Applied` 或 `Rejected(message)`。这些操作先检查目标并处理当前单元格编辑；非法草稿、组合输入、等待保存、禁用或未挂载时不执行，也不延迟重放。`moveColumn` 的索引沿模型完整状态数组解释，冻结位置保持不变。程序主动更新模型仍使用原模型入口及其编辑取消规则。

`minimumCenterWidth` 是 DataGrid 的逻辑中心区保留宽度，默认 80，允许显式设为零。用户新增冻结、显示冻结列或扩大其宽度时，按最近 Accepted 视口和当前列配置检查；冻结宽度增加且侵入保留空间时拒绝并说明原因。缩小或解除已有冻结始终允许，窗口本身变窄仍按 Start、End 顺序裁剪，不暗中解冻其他列。调宽及冻结只重新解析列几何，不读取行或重跑查询。

`fitColumns()` 明确调整全部可见列，先满足各列最小宽度，再以操作时当前宽度为比例权重，复用 `TableTracks` 分配剩余视口并遵守最大宽度；零宽列使用权重 1 参与恢复，正的小数宽度保留原权重。一次保存所有计算后的逻辑宽度。最小宽度总和超过视口时允许横向溢出，最大宽度总和不足时允许余白。隐藏列状态保留，冻结增长使用同一保留空间规则；滚动不自动触发适应操作。

`DataGridHandle.fitColumnToContent(id)` 显式测量一个未隐藏列，返回 `GridColumnFit`。其可观察 `result` 为 `Pending`、`Applied(width)`、`Rejected(message)` 或 `Cancelled`；`width` 是最终保存的逻辑宽度。`cancel()` 仅取消仍在等待的请求，完成后调用返回 false。同一挂载只执行一个请求，新请求通过检查后取消旧请求。未挂载、禁用、列已隐藏／移除或尚无可见布局时立即拒绝；当前编辑沿相同门控处理，非法草稿、组合输入和等待保存不启动测量，也不重放。

测量在下一次布局中复用该列真实表头与正文单元格，以无界横向约束取得内容自然宽度，再用正常约束放置同一子树。正文只测该帧实际呈现的行，包括部分可见行，排除仅为 overscan、焦点或编辑保留的离屏行；目标列横向离屏时也只为这些行准备该列。空结果仍使用表头和明确文字样本。自定义单元格沿普通 View 的无界横向测量规则提供自然宽度，不以语义文字替代真实内容，也不另建一套展示视图。

取表头、正文和列声明样本的最大宽度，加上真实单元格内边距，遵守列的最小／最大宽度；冻结列同时夹取到允许的增长上限。只有测量所属帧 Accepted 后才一次保存列宽。等待期间数据结果、列定义／状态、模型、字体集合版本／密度／方向、滚动状态对象改变，开始新编辑、失去可见区域、禁用或卸载时取消旧请求，保留应用新状态。普通滚动可改变下一帧的可见行范围；完成后滚动不继续调宽。查询结果与存活单元格身份保持不变。

`gridColumnsPanel(state, handle) { ... }` 组合现有 VirtualList、Checkbox、Select、Input 和 Button，显示全部列及其有效排序／筛选提示，提供显隐、选择待设置列、前移／后移、逻辑冻结、明确列宽、恢复列定义宽度、当前列适应可见内容以及全部可见列适应视口。内容测宽显示等待、成功、取消或拒绝状态，隐藏列须先恢复显示。列表按区域与用户顺序排列，前移／后移在相同冻结区域内操作，隐藏列仍在列表中。面板要求 handle 绑定该模型；未绑定时保留列信息并禁用操作。

列宽以逻辑单位输入，空草稿恢复列定义的 Fixed／Auto／Fraction，非法数值保留原文并显示错误。输入本身不改模型；Enter 或应用按钮才发布。组合输入期间不替换该草稿或执行其他面板操作，外部宽度／所选列／模型变化则使用新的应用值重建草稿。列表使用稳定列 ID；列调整与面板状态不创建业务单元格。

列面板的 `labels: GridColumnsLabels` 配置按钮、冻结选项、宽度提示、测宽状态、排序／筛选提示、列组说明与无障碍名称；列名、排序优先级和方向通过格式化回调传入。更新文案保留当前设置列、宽度草稿、焦点、列状态和查询结果；列 ID、逻辑冻结值及 automation id 保持独立。`error` 回调格式化操作返回的错误消息，默认原样显示。

表头逻辑 End 提供列宽手柄，复用 `tableColumnResize`。指针拖动、方向键每次 10 个逻辑单位、Home 恢复列定义，以及原生竖向 Separator 数值操作使用同一列状态。手柄、表头和正文服从同一列区域裁剪与显露范围；冻结区不接收被遮挡中心列的手柄输入。每次拖动开始先处理当前编辑，非法草稿、组合输入、等待保存及禁用时不启动，也不延迟重放。

拖动遵守列的最小／最大宽度；冻结列的增长同时受中心保留空间约束，到达上限后保持边界。窗口已过窄时仍可缩小现有冻结列。Escape、焦点离开、禁用或卸载取消本次拖动；仅当同一列定义与完整列状态仍是本次操作最后发布的快照时恢复开始状态，恢复可超过变窄后的保留空间。期间应用改列、换定义或替换模型时保留应用结果，旧回调不修改新的模型。单纯改行数据不被列宽恢复覆盖。

拖动不改变查询或排序优先级，保持仍存活的正文单元格和表头内容身份。原生绝对数值越界遵守 Window 的 InvalidArgument 合同；业务编辑或冻结规则拒绝时保留现值。当前固定手柄可通过 Tab 聚焦，表头主体仍用于排序。

表头主体沿水平方向拖动超过 6 个密度单位后进入列重排，复用 Drag 认领原始按下路径并取消该次排序点击；未越过阈值仍按普通表头点击处理。开始前通过同一编辑门控，非法草稿、组合输入、等待保存和禁用时不开始，也不重放。拖动中保留原列顺序，仅显示来源表头与插入线；在同一冻结区域内释放时一次性更新顺序，不改变列定义、查询、排序优先级或存活单元格身份。落在目标列的逻辑前半边时插入该列之前，后半边时插入该列之后；以该目标在完整状态数组中的位置更新顺序。隐藏列不作为指针落点，其他列的相对顺序保持不变。

落点以最近 Accepted 布局、当前横向滚动和表头实际区域计算，RTL 镜像物理位置。中心区拖动接近水平边缘时沿既有 ScrollState 与帧时钟自动滚动，离开边缘、结束拖动或抵达边界后停帧；冻结区不驱动中心滚动。跨冻结区或移出表头释放视为取消，冻结仍由列工具显式操作。Escape、焦点离开、禁用、模型／列快照／主题布局配置改变或卸载取消现有拖动，不回写开始时的列状态，不覆盖应用更新。普通行数据更新不取消列重排。键盘及无障碍用户通过列工具的前移／后移按钮执行相同列操作。

## 查找定位

`model.findCell(text, after = None, backwards = false, matchCase = false, wrap = true)` 返回 `GridFindMatch(address, wrapped)` 或 None。它在动作开始时捕获当前 Top／Body／Bottom 结果和可见逻辑列序，逐行读取允许导出列的数据文字，不创建 View、不改变查询或选择。纯操作列和不可导出列不参与；跨列显示仍按底层逻辑格的数据文字匹配。空查找文字直接返回 None。默认忽略 ASCII 大小写，其余 Unicode 按原文匹配；`matchCase = true` 使用原文子串匹配，不使用正则或额外搜索索引。

有效 `after` 从其后一个／前一个格开始；没有有效起点时从首格／末格开始。`wrap` 允许到达边界后继续，并通过 `wrapped` 标明命中跨越了边界；每格最多检查一次。查询顺序是逻辑列序，RTL 不反转；查找只覆盖当前可呈现结果，不能由查找隐式翻页或获取远端数据。返回值属于捕获的结果快照，模型层不承诺外部同时发布的数据仍含该地址。

`handle.findCell(...)` 使用相同参数和起点规则，返回 `GridFindResult.Found(match)`、`NotFound` 或 `Rejected(message)`；从活动格继续时传 `after = handle.focusedCell`。它先通过单格编辑门控，确认扫描期间模型、结果和列未改变，再清除矩形并经现有按 key 路径显露／聚焦目标。Found 表示定位请求已接受，实际焦点仍等待 Accepted；跨列目标归一到真实锚格。未命中、禁用、组合输入、非法草稿、等待保存和扫描失败不改变现有范围，也不重放旧操作。

`gridFind(handle) { ... }` 提供输入、上一项／下一项按钮和结果提示；Enter 查找下一项，连续操作记住上一次匹配地址，修改文字重新从边界查找。草稿不改变查询。`matchCase`、`wrap`、`labels`、字体／主题／焦点和 `onResult` 可配置，组合输入期间不提交查找；应用负责该组合控件的位置。

## 文本导出与单格粘贴解析

`gridCsv(rows, columns, includeHeaders = true)` 输出 CSV 字符串，使用逗号、CRLF、标准双引号转义，每条记录以 CRLF 结束。`gridTsv(rows, columns)` 输出适合矩形复制的制表符分隔文本，行间使用 LF，不额外增加末行换行。调用者明确提供数据范围及列顺序；这两个函数也接受 `GridRowSource<Row>` 并输出逻辑展示值；当前呈现含固定行／总计使用 `model.result.rows`，原始查询本页使用 `model.result.pageRows`，全部筛选结果使用 `model.result.ordered`。函数不取数、不持有文件或剪贴板、不创建 View，也不建立额外的单元格矩阵。

不允许导出的列被省略；全部列均不可导出时报告错误。可导出列必须提供数据文字，缺值由该列正常格式化。逗号／制表符、双引号、CR 和 LF 按对应格式加引号。不存在公式解析或导出为 Excel 公式的特殊分支。

`model.exportCsv(GridCsvOptions(...))` 在同一个快照中解析范围和列，然后复用 `gridCsv`。`scope` 缺省 `GridExportScope.CurrentPage`，包含当前呈现页；`AllFiltered` 包含全部筛选／排序结果；`SelectedRows` 按已选 key 的保存顺序读取完整本地来源，包含其他页和暂被筛选隐藏的已选记录。只解析选中 key，不扫描完整来源收集选择。

`data` 缺省 `GridExportData.Records`，导出原始业务记录；`Displayed` 明确导出逻辑展示结果，`includeTotals` 缺省 true，只包含该查询已启用的全筛选集总计与组小计；`includeGroups` 缺省 true，控制组标题行，两项互相独立。已选记录范围始终按业务选择解释。显示结果的总计标签位于所导出列中首个没有度量的列。

缺省 `includePinnedRows = true`：页和全部结果按 Top／Body／Bottom 导出，同一业务 key 只出现一次；已选范围只含实际选中的记录，不额外加入固定记录。设为 false 时排除当前配置的固定行。`includeHiddenColumns = false` 缺省仅含可见列，列序按当前逻辑 Start／普通／End 排列；可用 `columns = Some(ids)` 指定唯一列序，未知或重复 ID 拒绝，隐藏列仍服从显式包含选项，不可导出列始终排除。`includeHeaders` 缺省 true。应用持有输出文字并选择写入位置；格式化失败不返回半份 CSV，不执行文件或剪贴板写入。

`parseGridCellPaste(text)` 返回 `GridCellPaste.Value` 或带原因的 `Rejected`。允许标准引用字段、字段内部换行、转义双引号，以及一个可选的末行换行；多字段、多记录均拒绝，不截取首格。结束引号后的杂字符及未闭合引号也拒绝。该解析器供网格浏览模式使用，文本编辑器内的原生粘贴不调用它。

`DataGridHandle.pasteCell(address, text)` 从浏览状态对一个明确业务地址粘贴，返回 `GridPasteResult.Committed`、`Pending` 或 `Rejected(message)`。浏览格的原生 Paste 命令读取窗口剪贴板并沿同一入口执行；`onPasteResult(address, result)` 交付这次操作的即时结果，异步保存的最终结果仍使用编辑完成合同。多字段、只读格、失效地址、已有编辑或提交中的会话均不创建第二个草稿或额外提交。没有文本与空文本分别处理。

单字段先导入一个真实编辑草稿，再沿类型化解析、校验与应用提交。解析或校验失败保留草稿、错误及真实编辑器焦点；成功后返回当前格浏览。编辑器内的粘贴、剪切及文本撤销仍由其原生文本宿主处理，Textarea 中的未引用多行文字不会经过网格矩形解析器。

## 原生网格与定位

`dataGrid(state) { ... }` 创建 `DataGrid<Row>`，消费同一模型的当前呈现结果。`DataGridProps<Row>` 与 `DataGridBuilder<Row>` 提供外框宽高、行高模式／表头高、像素 overscan、可借用的 `ScrollState`／`DataGridHandle`、字体、主题及启用状态。尺寸按主题密度缩放；明确宽高受父约束限制。默认行高 48、表头高 40、外框高度 320。模型可以被多个挂载消费，但每个挂载有自己的滚动与焦点会话；一个 handle 或 ScrollState 同时只绑定一个挂载。

`labels = GridLabels(...)` 配置表格的无障碍名称、当前页／行选择名称、列／组拖动说明、调宽手柄名称及保存状态。行名称 formatter 接收从 1 开始的当前呈现序号，`resizeColumn(title)` 接收列标题。替换 labels 不改变查询、列几何、选择、焦点和活动草稿；文字不参与行列身份。`error(message)` 只格式化视图、调宽手柄和编辑控件收到的错误，`handle.editError`、模型结果与应用回调保留原消息。

`toolbar`、`footer`、`empty`、`loading` 和 `error` 均为可选的普通 View。`height` 始终表示包含插槽的整个外框高度；工具栏、状态提示和底栏按自然高度参与现有 Flex 布局，剩余空间归内部网格，表头仍在其视口顶部固定。外框不足时遵守父约束和普通 Flex 收缩，剩余网格高度可为零。`width` 和主题密度同样作用于整个外框，插槽内容自行使用既有主题控件。

提供 `error` 或 `loading` 时表示应用当前要显示该状态，错误优先于加载，状态条位于工具栏与网格之间。加载状态同时发布表格 busy，保留当前记录及可用交互；应用可显式设置 `enabled = false` 来禁止网格输入。无错误／加载状态且当前呈现行数为零时，`empty` 居中显示在表头以下的正文区域；没有提供的插槽不显示默认文案。状态插槽不启动加载或执行重试，View 内的按钮使用应用自己的回调。

插槽有各自的稳定父节点，内部网格持续挂载，增加、删除或更新插槽不重置模型、滚动、选择和编辑草稿。正文高度变化沿既有阅读锚点及焦点显露规则处理。所有插槽位于网格输入域之外，工具栏、底栏和错误重试按钮不因网格本身禁用而一并禁用；焦点进入插槽时沿正常的外部焦点编辑规则处理。

普通父 Element 拥有唯一滚动视口，表头与正文分别按列、按行虚拟化，每个正文行再按列虚拟化。所有条目使用本次 `LayoutInput` 中的相同列宽和滚动结果；scene 只消费自己的完整 LayoutResult。列宽复用 `TableTracks`，Auto 只测表头及声明的文字样本，不创建业务行。横向滚动只挂载可见列、冻结区、自动行高贡献列和实际活动项；不为每个行列组合预建 View 或 FocusHandle。

Start／End 冻结随 RTL 转换到对应物理边。它们与中心共享同一套列宽和单元格实例。表头保持垂直固定，正文不能绘制或命中表头区域。窄窗口先保留 Start，再裁剪 End，中心剩余宽度可以为零；零面积不发布命中区域。

每格的 LayoutResult 保存所属区域及同一真实视口。原生显露、焦点和内容控件使用这份实际区域：中心格避开两侧冻结区，正文避开表头，冻结格只沿纵轴显露，表头不因显露改变正文的纵向位置。RTL 使用对应的物理区域；没有可用区域时不能通过显露取得焦点。

`GridCellAddress(row, column)` 使用 `GridRowKey` 与 `GridColumnId`；传业务 ViewKey 时构造 Data 地址。`DataGridHandle.focusCell(address)` 接受当前结果中的业务行、组行或总计行与有效可见列，返回请求是否接受；真实焦点必须等布局 Accepted 后落到该格的真实 FocusHandle。`focusedCell` 反映实际焦点（包括自定义内容后代），`pendingCell`／`isPending` 反映尚未完成的请求。`cancelFocus()` 只取消定位请求。目标删除、禁用、外部焦点或新请求沿原 UI 焦点路径取消旧请求，不能在迟到帧中复活。表头排序沿模型入口执行。

表头点击按未排序、升序、降序、未排序循环。`multiSortModifier` 默认 `GridMultiSortModifier.Shift`，可配置为平台 `Primary`；按住配置的修饰键追加或调整该列排序，其余排序维度与既有优先级保留。普通点击只保留当前列。表头显示方向，多列排序时同时显示从 1 开始的优先级，语义名称与可见标题一致。表头取得真实焦点后，普通 Enter／Space 使用单列排序，配置的修饰键加 Enter／Space 使用多列排序；自动重复不连续切换方向。所有入口先经过当前编辑会话的提交规则，非法草稿、组合输入与等待保存不会执行新的排序。不可排序列不执行排序动作。

原生表格按稳定的行 key 与列 ID 描述完整当前结果，读取离屏单元格值不创建 View、焦点目标或执行 I/O。明确的 Realize 动作只准备目标行和列，不滚动或抢焦点；Reveal 显露该格并保留已有焦点；Focus 使用同一个真实单元格焦点与 Accepted 布局路径。`pendingCell`、`isPending` 与 `cancelFocus()` 同样覆盖原生 Focus 请求。取消某格原生焦点只影响该格的真实子树。隐藏列、删除行、禁用或卸载使相应动作失效；已退役的原生代理不会因复用业务 key 而复活。

## 顶部与底部固定行

`GridPinnedRows(top = [], bottom = [])` 用有序的显式业务 key 定义固定状态；两个区域内及区域之间都不能重复，不能使用 `ViewKey.Position`。模型构造可传 `pinnedRows`，之后使用 `setPinnedRows(value)` 一次替换完整配置，或 `pinRow(key, GridRowPin.Top／Bottom／None)` 将单行追加到指定区域／解除固定。同区域重复固定保持原次序。引用必须存在于原始来源，非法更新不发布部分状态。

固定行从全部筛选后 `ordered` 结果中按配置顺序取得，可独立于当前页显示；当前页中相同 key 从正文移除，不补入下一页记录。排序不改变固定次序，筛选不匹配时暂不显示但保留配置，来源删除 key 时清理配置。固定不重跑查询，也不改变 `ordered`、`totalRows`、`pageCount` 或聚合输入。配置与呈现映射只处理固定 key，不扫描全部业务行或预建 View。

`DataGridHandle.pinRow(key, pin)` 是用户操作入口，返回 `GridRowActionResult.Applied` 或 `Rejected(message)`。非法草稿、组合输入、等待保存、禁用或未挂载时不执行，也不延迟重放；同步提交后重新检查当前来源与固定状态，保留期间应用替换的配置。直接模型操作仍遵循正常外部更新与编辑生命周期。

顶部、正文、底部共用一个按 key 的 LazyElement、一个原生 Table 和同一列布局。同一行固定／解除固定时保持真实单元格身份，导航按三个区域的逻辑次序继续。固定行不随正文纵向滚动，中心列仍横向滚动，冻结列遵守同一区域裁剪。按 key 或原生 Focus／Reveal 到固定行只调整需要的横轴，不改变正文纵向阅读位置。正文显露避开表头及上下固定区。

固定行使用相同的固定／显式／内容行高。可用高度先给 Top、再给 Bottom，剩余给正文；固定区超高时按配置从起点裁剪，正文可退化为零高，不暗中解除固定。只准备当前可见固定行及实际活动项；解除固定可由外部控件调用 handle，Tab 仍可离开网格。自动内容测宽包含三个区域的实际可见行，排除其余保留行；最近 Accepted 的阅读锚点只描述正文，固定区域的高度变化通过同一布局调整保持正文 key 与项内偏移。

## 行高与阅读位置

`rowSizing: GridRowSizing<Row>` 选择一种行高模式，`rowHeight` 始终是正的有限逻辑单位。默认 `Fixed` 让全部行使用 `rowHeight`。`Explicit(height)` 按实际 Row 调用 `(Row) -> Double`，结果同样必须有限且大于零；`rowHeight` 是未测量行的估计高度。回调是只读测量，不执行数据更新或 IO。

`Content(columns)` 接收非空、无重复的现有列 ID。它以 `rowHeight` 为最小值和初始估计，按指定列在当前列宽下的真实 View 自然高度决定整行高度。隐藏或零宽的贡献列不参与，删除配置中的列须同时更新行高配置；没有有效贡献列时使用最小高度。默认文本允许换行，自定义 View 和实际编辑器继续使用其普通测量规则。其他列不会因为自身内容较高而增高整行。

对可见行、overscan 和真实活动行，所有未隐藏的高度贡献列都会按需准备，包括横向离屏列；其他列继续横向虚拟化。每格只有一个真实实例，自然高度测量后用最终整行高度放置同一子树。内容测宽仍只测实际可见行，并使用各行当前高度；不会把离屏保留行纳入宽度样本。

高度索引复用公开 `ItemExtentIndex`，只记录已测量行；不为构造滚动范围扫描或分配全部 Row。尚未测量行保持估计值，滚动范围随着测量收敛；按 key 定位先测量目标及实际视口，不能把估计总高度当成完整数据的精确高度。数据／顺序更新可按稳定 key 复用已知高度作为估计，可见行仍重新测量。

最近 Accepted 的首个可见行 key 与行内偏移是阅读锚点。行高、数据顺序、列宽、字体或密度变化后，在新高度中保留该 key 和夹取后的行内偏移；原 key 消失时采用最近有效索引，空结果归零。新的显式滚动或单元格定位优先于旧锚点；更换模型或 ScrollState 不沿用旧锚点。修正通过同一视口的 `ScrollAdjustment` 发布，Discarded 帧不写 ScrollState，也不取代 Accepted 锚点。PageUp／PageDown 使用最近成功呈现的行几何，保持列并至少移动一行。

## 行内跨列显示

`DataGridProps.columnSpans`／builder 的同名属性为可选 `(Row) -> Array<GridColumnSpan>`。`GridColumnSpan(columns)` 用不少于两个、无重复的稳定列 ID 明确成员及其逻辑顺序，第一个成员是锚点；不依赖标题或当前像素宽度。回调只读取传入的不可变记录，按实际呈现、定位或语义查询的行求值，不扫描完整来源。数据或规则改变须发布新的来源快照或回调。

跨度只有在成员均存在、可见、属于同一冻结区，且在该区域包含隐藏列的完整列顺序中保持所声明的连续次序时才生效。隐藏成员、隐藏列隔断、重排或冻结变化导致条件不满足时，该声明暂时不生效，各列恢复普通单元格；恢复条件后重新生效。同一行的有效跨度不能重叠，违反时抛出 `IllegalArgumentException`，不按声明先后默默选取其中一个。

跨列只改变呈现，使用锚点列的真实 View 和文字，总宽度为成员列宽之和。被覆盖列不创建 View、FocusHandle 或语义节点；锚点本身离屏而覆盖区可见时仍挂载。列、行固定和 RTL 沿同一布局，跨列不会越过所属区域的裁剪。实际单元格和离屏原生元数据发布一致的 columnSpan；查询覆盖列得到同一锚点，Realize／Reveal／Focus 操作同一实际控件。跨度变化后被覆盖的独立节点永久退休，拆分时创建新节点，存活锚点保持身份。

`focusCell` 和导航把覆盖列定位到锚点。逻辑向前箭头和 Tab 跳过整个跨度，反向进入前一实际格，上下／翻页／首尾定位按目标行重新解析；网格末尾的 Tab 正常交还外部焦点顺序。当前格被新的跨度覆盖时，活动焦点转到新的锚点，旧请求不再追踪已经退役的格。

跨度大于一的格只读，锚点与覆盖列的单格编辑、粘贴入口均拒绝。外部更新使正在编辑的格成为跨列的一部分时，以 `ColumnChanged` 结束原编辑；迟到的保存完成仍按原会话生命周期失效。显示不改动任何列的底层业务值，复制／CSV 始终按各逻辑列取原值，不重复锚点文字；自定义 View 中已有的普通控件仍遵循单元格内容交互合同。

自动行高配置中的任一成员可让该跨度参与高度测量，使用锚点真实内容及合并后的宽度，同一格仅测一次；默认文本按合并宽度换行。单列内容测宽忽略跨度大于一的格，仍使用该列真实叶表头、其余可见的独立格和明确样本，不把合并内容宽度归给某一成员。关联表头按成员次序包含各自真实挂载的祖先和叶表头，同一引用只出现一次。表头树重组保留仍存活目标的引用，删除或隐藏目标后才移除对应关系。

## 键盘浏览与单元格内控件

浏览目标是每格真实的外层焦点。左右键按物理方向移动，RTL 下反向解析逻辑列；上下键保持列身份。Home／End 到当前行的首／末可见列，Primary＋Home／End 到当前结果的首格／末格。PageUp／PageDown 按最近 Accepted 的正文高度移动，保持列；箭头与翻页在边界停住，Tab／Shift＋Tab 按行列顺序换格，越过网格首尾后交给现有外部 Tab 顺序。隐藏列不参与浏览，冻结列与中心列共用顺序。

每个自定义单元格的内容是一个真实 FocusScope。Enter／F2 从浏览目标进入其实际控件；内部 Tab 先遍历该格的控件，离开边界才换格；内部未被控件或弹层处理的 Escape 返回该格浏览目标。内容消费的箭头、文字和 IME 事件不会再触发网格导航。普通点击仍沿现有输入归属，子按钮认领的点击不会再次激活外层。

矩形拖选、边缘滚动与键盘／点击选择使用同一范围模型；其实际验证结果记录在进度文档。

## 有类型的单格编辑

`gridColumn` 的可选 `edit` 由 `gridEdit<Row, T>` 构造。编辑器工厂、相等比较、同步校验和应用提交始终保留 `T`；`GridColumnEditing<Row>` 只封装对共同列接口必要的操作，不提供动态值盒。列可用 `editable` 按记录决定是否允许编辑。

`GridEditor<T>` 返回 `GridCandidate.Value(T)` 或 `Rejected(message)`，通过 `GridEditorOptions` 接收真实焦点、字体／主题、错误、提交中状态和提交回调。`importText(text): String?` 只导入当前单格草稿，成功返回 None，不能导入时返回原因且保留旧草稿；不执行应用提交。内置 `GridTextEditor<T>` 复用 `TextEditorState` 与 Input／Textarea，保留导入的原始文字供解析与错误修正，组合输入期间拒绝导入；文本、Long 和有限 Double 提供便捷工厂。自定义编辑器沿相同合同使用真实控件，组合输入由编辑器报告和处理。

`gridBooleanEditor` 使用 Checkbox，Space 改变草稿，Enter／Tab／失焦沿网格提交；文本导入接受 true／false、1／0 和“是”／“否”。`gridDateEditor` 使用 DatePicker 与公开的 DatePickerDraft，值为非空 LocalDate，文字格式为 YYYY-MM-DD。日期输入确认或日历选择提交当前格，选择原日期仍按不变值结束。Escape 先关闭日历；弹层已关闭且没有组合输入时，通过会话绑定的 `onCancel` 取消当前格草稿。

`gridChoiceEditor<T>` 使用 Select，接收现有 `Choice<T>`（稳定 key、类型化值、显示名及 enabled）。默认粘贴只匹配唯一可用显示名；重名、未知或禁用项返回错误，可提供类型化 parse 回调，但结果仍须是可用选项。选择及显式关闭选项弹层提交当前格，Escape 先关闭弹层。选项名称不作为身份。布尔、日期与选项编辑器通过既有 Field 呈现业务错误与提交中说明，保存期间限制修改。

内置编辑器和便捷工厂接受 `labels = GridEditorLabels(...)`，配置解析／组合输入错误、布尔显示、选项占位与不可用状态、日期占位和日历按钮名称。配置在创建该草稿时捕获，不通过重新创建编辑器改变活动草稿。布尔导入规则和严格 ISO 日期格式保持不变；本地化不改变实际 Boolean／LocalDate／Choice 值。`calendarLocale` 直接采用组件库的 `CalendarLocale`，涵盖月／星期／数字／日期及前后翻月名称；筛选面板的 `GridFilterLabels.calendarLocale` 使用同一接入方式。`GridEditorOptions.savingText` 将网格当前保存提示传给内置或自定义编辑器。

带原生弹层的编辑器在打开至 `onClosed` 期间用 `holdsFocus`（默认 false）保留没有实际焦点的交接间隙；真正移到外部目标仍按失焦提交。弹层释放输入域、完成焦点恢复后调用 `onFocusSettled`。所有编辑器回调只作用于创建它的会话。选择弹层中的 Tab／Shift+Tab 先关闭弹层，再通过 `onNavigate` 交还原始按键，焦点仍属于该格时沿 Grid 行列顺序继续；不合成按键或让 Select 自行跳出整个网格。

每个挂载只有一个会话。Enter／F2 或 `DataGridHandle.beginEdit(address)` 进入可编辑格；焦点通过既有 LazyFocus 请求落在真实编辑器。不可编辑的交互格仍进入自己的内容焦点域。`editingCell`、`editError`、`isSubmitting` 可在 render 中观察当前会话，包括首次绑定前的读取。`commitEdit()` 返回 NoEdit／Committed／Rejected／Composing／Pending；`cancelEdit()` 显式结束草稿。

提交先解析、校验，并重新核对行 key、列定义、可编辑条件和原字段。新值相等时不调用应用。`GridChange<Row, T>` 提供当前 Row、原值和候选值，应用通过 `GridCommit<Row>.accept(source)` 安装真实不可变数据快照，或 `reject(message)` 保留草稿及错误。应用可异步保留 completion；Pending 期间禁止重复提交和新编辑。回调只能在 owner 线程使用，并且只完成原会话一次；过期回调返回 false，不改写模型。应用自己的远程副作用仍由应用管理。

双击可编辑格进入编辑，子控件已认领的点击继续由子控件处理。Enter 提交后返回该格浏览；Tab 提交后按当前记录和目标 key 导航。首尾边界沿普通 UI 父级焦点遍历继续，异步保存完成后同样兑现这一方向。网格内点击其他单元格或表头，在原输入路由的 capture 阶段先尝试提交；错误、组合输入或等待保存时拒绝这次点击，避免已执行排序或子按钮动作后再回退。组合输入未完成时不读取 preedit 作为候选。Escape 先由原生输入法／编辑器处理，未消费时取消当前草稿。文本内撤销使用原生单格历史。

焦点离开编辑格到网格外控件时尝试提交，成功后保留外部焦点；校验失败会重新显露编辑器。异步保存期间允许应用外部控件继续取得焦点，Grid 保留当前草稿和提交状态。窗口失去前台激活本身不等于更换逻辑焦点。禁用、删除与卸载先执行取消规则，不因清理引发自动保存。

编辑期间的错误和保存提示由网格在该格旁的普通 Portal 中显示，不占用固定行高内的输入空间，也不计入自动内容行高。提示不取得焦点、不拦截 Escape 或外部点击；锚格不可见时隐藏，编辑结束或卸载时清理。内置编辑器同时在真实控件上发布 description／error 语义，保持原草稿和输入区域；不再把提示作为 Input／Field 下方的附加布局。自定义编辑器仍收到相同的 `GridEditorOptions`，可以组合自己的控件。

数据替换保留字段未变的草稿，包括同一 Row 的其他字段更新。删除记录、隐藏目标列、替换该列定义、字段变更、禁用和卸载结束旧会话；`onEditEnd` 报告地址及原因。模型通知在实际动作时处理，因此窗口隐藏也不会让已删除记录的会话继续存活。提交成功后重新查询；原 key 不再显示时移到同列最近有效行，空结果回到网格入口。普通滚动保留实际活动编辑器且沿原视口裁剪。

按行列预定位只用于目标条目尚待准备的阶段；选中真实焦点目标后沿其实际几何显露。宽于中心视口的单元格进入编辑时，编辑器的内边距与焦点范围不能被整格预定位反复覆盖。

浏览状态下，首个非空原生 Commit／Preedit 可以直接开始单格编辑。Grid 通过公开 `scope.textInputStarter` 把同一 TextEditorState 和原生连接交给实际编辑器，保留 Unicode、组合、选词、撤销事务和候选位置；不从 LogicalKey.Character 重建文字。直接输入从空草稿开始，原字段仍作为提交基线；双击、Enter／F2 和显式 beginEdit 继续保留原值。

`GridEditor.startInput(state): TextInputStartOptions?` 默认返回 None。接受直接输入的自定义编辑器须采用传入状态，并返回与实际 TextEditHost 相同的 policy／multiline 配置；不得改写该状态或自行插入首字符。内置文本／整数／浮点编辑器接受直接输入；布尔、日期和选项编辑器继续通过显式进入及自身控件操作。None 只拒绝这次直接开始，不发布编辑会话。

只读、禁用、跨列显示或当前存在其他编辑会话时不直接开始。接管前取消、隐藏／删除、模型替换及卸载会同时取消等待输入；接管后沿既有单格取消与提交规则处理。原始非法数值文字保留在同一草稿，解析／业务校验拒绝不回填旧字段。系统拼音回归同时覆盖浏览首键与显式进入，结束后恢复原输入源。
