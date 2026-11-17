# 三个 GitHub 仓库的创建与首次上传

已准备的本机目录：

| 本机目录 | 建议远程名称 | 创建方式 |
|---|---|---|
| `/home/ldb/xd-uav-system` | `xd-uav-system` | 在原仓库页面点 Fork |
| `/home/ldb/ground_station` | `uav-ground-station` | 新建空仓库 |
| `/home/ldb/uav-integration` | `uav-integration` | 新建空仓库 |

两个新仓库由用户在 GitHub 创建，名称分别为 `LiDaibo122/uav-ground-station` 和 `LiDaibo122/uav-integration`，本地 origin 已指向对应地址，分支使用 main。底座保留原始历史，联调分支为 `integration/ground-station`；尚未配置用户 Fork 的 origin。本说明的创建与首次提交命令供新环境参考，已有提交时无需重复首次提交。

提交身份仅在两个本地仓库设置为 `LiDaibo122` 和账号对应的 GitHub noreply 邮箱，未修改全局 Git 配置。当前 WSL 通过 Windows Git Credential Manager 的已登录账号认证；凭据只由凭据管理器使用，不写入仓库。其他电脑应配置自己的认证方式，该本机 helper 配置不随代码提交。

## 1. 在 GitHub 网页创建

1. 打开 https://github.com/yuan99993/xd-uav-system ，点击 **Fork**，Owner 选你的账号，名称保持 `xd-uav-system`。默认 dev 分支足够首轮使用。底座包含上游已追踪的大量模型/数据及 `.venv-sar` 历史，使用 Fork 保留来源，不通过复制文件或改写历史建立新底座。
2. 点击 GitHub 右上角 **+ → New repository**，创建 `uav-ground-station`。
3. 同样创建 `uav-integration`。
4. 两个新仓库按你的协作需要选择可见性；不要勾选初始化 README、.gitignore 或 License，因为本地已有待提交内容。底座保留原许可证，自研代码的开源许可另行决定。

官方说明：[Fork](https://docs.github.com/en/pull-requests/how-tos/work-with-forks/fork-a-repo)、[创建仓库](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-new-repository)。

## 2. 配置本机提交身份

填写你自己的提交名称和邮箱（可以使用 GitHub 提供的 noreply 邮箱）：

```bash
git config --global user.name "你的Git提交名称"
git config --global user.email "你的GitHub邮箱或noreply邮箱"
```

这两个配置只是提交身份，不会登录 GitHub。推送需要你已有的 GitHub HTTPS 凭据或之后配置 SSH；不要把访问令牌写入 remote URL 或文件。

## 3. 配置 remote

把最后一个参数换成你自己的 GitHub 用户名：

```bash
cd /home/ldb/uav-integration
bash scripts/configure_remotes.sh 你的GitHub用户名
```

脚本仅修改本地 remote，不创建仓库也不推送；重复运行相同账号可复用，遇到不同的已有 origin 会停止并保留原配置。

最终应为：

```text
xd-uav-system:
  upstream → https://github.com/yuan99993/xd-uav-system.git
  origin   → https://github.com/你的用户名/xd-uav-system.git
ground_station:
  origin   → https://github.com/你的用户名/uav-ground-station.git
uav-integration:
  origin   → https://github.com/你的用户名/uav-integration.git
```

底座的 upstream 已经配置，不需要再 rename origin；默认推送目标设置为 origin。本地已经把 upstream 的 push URL 设置为 `DISABLED`，用于防止误推，fetch URL 保持原仓库。`git remote -v` 中看到它是预期结果。后续确需更新你自己的 origin 地址，用：

```bash
git -C /home/ldb/ground_station remote set-url origin https://github.com/你的用户名/uav-ground-station.git
```

只有已经存在的 remote 才用 `set-url`；首次添加使用脚本或 `git remote add`。[GitHub remote 说明](https://docs.github.com/en/get-started/git-basics/managing-remote-repositories)

## 4. 首次提交并上传

先提交地面站：

```bash
cd /home/ldb/ground_station
git status --short
git diff --cached --stat
git add .
git commit -m "Initialize civilian UAV ground station"
git push -u origin main
```

把底座联调分支推到你的 Fork：

```bash
cd /home/ldb/xd-uav-system
git status --short
git push -u origin integration/ground-station
```

当前分支没有底座功能改动，上传的是基于已知 dev 提交建立的联调分支。不要强推或覆盖原仓库的 dev。

最后记录并上传联调版本组合：

```bash
cd /home/ldb/uav-integration
python3 scripts/record_versions.py
git add .
git commit -m "Initialize ground and XD integration contracts"
git push -u origin main
```

后续每次形成可复现版本，在地面站/底座分别提交并确认工作区干净，然后重新运行 `record_versions.py`，提交更新后的 lock 文件。`python3 scripts/record_versions.py --check` 可检查本机是否匹配该基线。

## 5. 以后如何改底座

底座修改只在联调或独立修复分支提交，并推到你自己的 origin；按单项改动向原仓库 dev 发 Pull Request，由底座负责人审核合入。

```bash
cd /home/ldb/xd-uav-system
git fetch upstream
```

fetch 只下载更新，不自动合并。需要升级联调基线时，由双方确认版本后再合并/变基、验证并更新 lock。

## 本机检出与上传范围

底座采用部分克隆和稀疏检出，仅在本机不展开上游 `.venv-sar/`。其历史和远程分支没有删除，后续可用 `git sparse-checkout disable` 展开；上游模型仍属于其原始历史。本地模型二进制也不等于可直接跨硬件运行的模型服务。

地面站排除了 node_modules、dist、runs、reports、第三方检出目录、编译产物、环境文件和模型权重；本机已有文件未删除。第三方源码按 `third_party/SOURCES.json` 恢复：

```bash
cd /home/ldb/ground_station
npm ci
python3 -m pip install -r requirements-simulation.txt
python3 scripts/fetch_auction_sources.py --build-baseline
npm test
npm run build
```

历史模型回放/浏览器验收脚本有些需要本机旧 runs/reports；这些不属于首次克隆的默认单元测试必需数据。旧会话专项用例在数据缺失时会跳过。PX4/Gazebo、ROS 和模型服务仍需另行配置。
