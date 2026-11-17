# 地面站与 XD 接口约定（草案 v0.1）

适用 XD 基线：`5289177fcb8c85bc9986c5f4ca11d1ea75ac3bb0`。本文件是联调约定，不是已经完成的网关实现。

## 职责

地面站负责自然语言理解、任务生命周期、CBBA/拍卖分配与操作记录。XD 负责规划校验、航路执行、起降、状态估计及机载保护。首轮由地面站最终派单，不同时启动 XD 自动分配节点；该包的 ROS 消息/服务定义仍可能是 planning 的构建依赖，不删除其消息包。

地面站业务工具调用统一网关，网关由独立 ROS1 进程实现。先在局域网验证 ROS1 接口，外部传输形式以后由网关封装。LLM 不直接生成底层高频 setpoint，不调用 `controller/internal/command`。

## 公共接口

| 功能 | XD 相对接口 | ROS 类型/语义 |
|---|---|---|
| 统一控制状态 | `control_manager/state` | `xd_uav_controller/ControlState`，含定位有效性和状态新鲜度 |
| 机群世界位置 | `state_estimator/main/frames/world/odom` | `nav_msgs/Odometry`，须核对实际部署输出和 frame |
| 解锁、离地、电量 | `mavros/state`、`mavros/extended_state`、`mavros/battery` | 不能只根据模式或 ControlState 推断已起飞 |
| 起飞 | `control_manager/takeoff` | `xd_uav_controller/Takeoff`；服务成功表示请求结果，不代表已离地 |
| 完整航路 | `planning/task_path` | `nav_msgs/Path`；固定翼至少两个 XYZ 点，使用共享 frame |
| 航路取消/交接 | `planning/cancel` | `xd_uav_task_allocate/CancelPlanning`；携带当前 goal_id，失败则不继续交接 |
| 返航降落 | `control_manager/land_home` | `std_srvs/Trigger`；Home 语义与着陆方向由底座配置确认 |
| 控制器保持/外部参考开关 | `control_manager/external_control` | `std_srvs/SetBool`；与 planning 取消及恢复重发一起编排 |
| 航路反馈 | `planning/status` | `xd_uav_task_allocate/PlannerStatus`，严格匹配当前 goal_id |
| 规划健康 | `planning/healthy`、`planning/diagnostics` | 健康不等于到达 |
| 世界观测（可选） | `detect/detections_world` | `xd_uav_detect/WorldDetectionArray`，保留位置有效性、来源与置信信息 |

以上相对接口统一加 `/<uav>/`。公共禁飞区入口为 `/planning/no_fly_zones`，消息为 `xd_uav_planning/NoFlyZoneArray`。使用底座的消息定义，不在地面站复制同名 msg/srv。

## 标准业务数据

- 命令：`schema_version`、`command_id`、`mission_id`、`vehicle_id`、`action`、`issued_at`、`expires_at`、`frame_id`、`payload`。
- 航路：明确 XYZ、单位、frame 和高度基准；地面任务 ID 映射到 uint32 `goal_id`，映射由网关保存。
- 状态：飞机 ID、采样时间、接收时间、位置、速度、电量、解锁/离地状态、定位健康、当前任务与来源；未知值不能以正常值补齐。
- 结果：`command_id`、`mission_id`、`vehicle_id`、`goal_id`、阶段、错误码和原因。至少区分接收、执行中、完成、失败、取消与结果未知。
- 观测：结构化位置/类别/置信度/有效性与简短文本并存；持续传感器更新不直接触发 LLM。

相同命令 ID 不重复产生动作。断线重连先查询真实状态；没有回执不等于没有执行。当前轮缓存不能替代跨重启去重存储。

## 底座特有约束

1. world 来自 XD 的 datum/TF，不能沿用地面站当前仿真硬编码原点。必须核对 ENU、机体 FRD/FLU 和高度基准。
2. 当前固定翼 Path 通过各嵌套 PoseStamped 的 `header.seq` 携带 `goal_id`；顶层 Header.seq 会被 rospy 重写。适配时遵守底座基线协议，后续升级显式 ID 消息需双方同步。
3. 发 Path 时使用当前 ROS 时间，满足底座的新鲜度要求；不能直接把用户任务创建时间当作 ROS header.stamp。
4. 暂停/返航前先取消活动 planning 并确认交接；恢复时重新生成并发送剩余航路，不能假设重新打开 external_control 会重放旧命令。
5. `REACHED` 是该航路目标的完成反馈，不表示每个几何采样点都产生独立完成事件，也不表示已着陆。抵达后的观察/跟踪另接 `task_execute/execute` action。
6. 固定翼不能原地悬停；目前底座固定翼规划含禁飞区绕飞，不承诺固定翼点云避障或多机碰撞规避。

依据：上游 `xd_uav_planning/docs/TASK_PLANNING_INTEGRATION.md`、`xd_uav_control_manager/README.md` 和对应代码。后续修改这份约定时与基线版本一起提交。
