# ADR 001：地点身份与本地记忆

状态：已采用；API 26 真机数据库 9 项测试已通过（2026-10-06）。

Place 表示稳定的物理地点，Visit 表示一次到访。两者使用独立 UUID。重访从详情页直接指定 Place ID；附近 150 米仅提供候选，由用户选择，不能将相邻店铺按距离自动合并。完全一致的规范名称、坐标和 CRS 作为重复输入保护；尚无可靠 POI 身份时不猜测。

创建 Place 与 Visit 在同一事务提交，写操作由 Repository 串行排队。Visit ID 同时作为请求 ID，用于保存重试的幂等性。提交后才刷新界面与触感；刷新失败不能误报成写入失败。查询关闭 ResultSet，用户文本通过绑定参数传递。

firstVisitedAt、lastVisitedAt、visitCount 与 visitedYears 从 Visit 聚合；删除和补记不维护容易失真的缓存。历史页的摘要与 Visit 列表读取也进入串行队列，避免应用内写入发生在两个查询之间。最后一次 Visit 被删除时保留 Place 身份，后续仍可重访。

每次到访保存 UTC 时间、当时 UTC offset 和 localDate。时间轴依据 localDate，而非用户后来切换的时区。地点坐标明确记录 WGS84 / GCJ02；定位、落旗和相机焦点均通过官方 `map.rectifyCoordinate` 处理区域坐标差异。坐标系不同不做直接距离匹配，不引入自编转换算法。

数据库使用 S3 与 schema version。当前 schema 为 v2：新库在事务内创建 v1 表和索引，再安装 v2 关联保护。真机证明 transaction 连接不继承主连接的 foreign_keys PRAGMA，因此 v2 使用持久化触发器保证 Visit 的 Place 存在、Place ID 稳定及删除级联。升级前校验孤立 Visit，异常则回滚并保留原库。未来增加实体时逐版本迁移。遇到高于应用支持的版本拒绝打开并保留数据，不进行破坏性降级。

当前 Memory 只有纯文本与五档 Mood。媒体文件、Trip 与 Track 在闭环通过后的独立迁移中加入。平台服务可失败，失败时保留用户输入；当前轮尚未验证的路径见 progress.md。
