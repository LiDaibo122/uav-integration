# UAV Integration · 民用无人机集群联调

本仓库只维护地面站与 XD 底座之间的接口约定、联调配置和版本组合。业务实现分别保留在另外两个仓库，不复制底座代码，不改变原有代码的归属。

| GitHub 建议名称 | 本机目录 | 职责 |
|---|---|---|
| `xd-uav-system` | `../xd-uav-system` | 原仓库的 Fork；保留上游历史及许可证 |
| `uav-ground-station` | `../ground_station` | Qwen、任务分配、界面、仿真执行器及未来适配层 |
| `uav-integration` | 当前目录 | 接口、配置、版本基线和联调流程 |

当前状态：底座从 `yuan99993/xd-uav-system` 克隆，基于 `dev`，本地使用 `integration/ground-station` 分支；底座功能代码未修改。地面任务分配模块已独立到 `packages/task_allocation/`，旧导入保留。XD 适配器尚未实现，尚未完成 ROS 联调，也未启动底座仿真。

## 文件

- `contracts/GROUND_XD.md`：业务边界、接口映射、控制交接与结果语义。
- `config/xd_ros1.example.json`：待校准的命名空间、坐标与连接配置。
- `versions.lock.json`：底座与地面站已提交源码的 SHA；运行时联调尚待进行。
- `scripts/configure_remotes.sh`：在本地设置三个仓库的 origin，不创建远程仓库、不推送。
- `scripts/record_versions.py`：记录或核对地面站和底座的已提交版本。
- `docs/GITHUB_SETUP.md`：创建远程仓库、首次提交与推送的完整操作。

## 先做什么

地面站远程为 https://github.com/LiDaibo122/uav-ground-station ，本仓库远程为 https://github.com/LiDaibo122/uav-integration 。两个本地仓库的 origin 已分别配置。底座目前保留原 upstream，尚未配置用户 Fork 的 origin。

后续先接 XD 单机状态，再验证单机任务，再扩展至多机和 Qwen。底座如需推送修改，先建立自己的 Fork；新环境配置和版本升级方式见 GitHub 操作说明。

本仓库配置是接口预留示例，当前服务不会自动读取它。飞机类型、Home、跑道方向、world 原点、TF 和 PX4 参数须在开始联调前由双方确认。
