# Windows Update Disabler (彻底永久禁用 Windows 10/11 更新)

🚀 **一键彻底封锁 Windows 自动更新、防死灰复燃、支持一键恢复**。全面兼容 Windows 10 / Windows 11（家庭版与专业版）。

---

## 🌟 核心功能

1. **服务级完全停用**：
   - 彻底禁用 `wuauserv`（更新核心服务）、`WaaSMedicSvc`（更新医护与复活服务）、`UsoSvc`（调度器）、`dosvc`（传递优化）、`BITS`。
   - 清除服务的崩溃重试恢复机制（Failure Actions），防止服务自动被拉起。
2. **计划任务斩草除根**：
   - 夺取 `UpdateOrchestrator`、`WindowsUpdate`、`WaaSMedic` 目录权限并禁用所有后台自动扫描、唤醒与静默安装任务。
3. **注册表深度策略**：
   - 写入组策略级拦截项（`NoAutoUpdate`、`AUOptions=1`、`DisableWindowsUpdateAccess`）。
   - 禁止系统自动联网搜索与安装硬件驱动。
   - 禁止应用商店后台静默下载组件。
4. **支持一键完整复原**：
   - 内置 `restore.bat`，随用随关，需要更新时可秒级恢复所有系统默认配置。

---

## 📁 目录结构

```text
windows-update-disabler/
├── disable.bat               # 双击运行：彻底禁用 Windows 更新（自动请求管理员权限）
├── restore.bat               # 双击运行：恢复 Windows 更新到默认状态
├── scripts/
│   ├── disable-windows-update.ps1   # 禁用更新的完整 PowerShell 核心逻辑
│   └── restore-windows-update.ps1   # 恢复更新的完整 PowerShell 核心逻辑
├── README.md
└── LICENSE
```

---

## 🛠️ 使用方法

### 禁用更新
1. 直接双击运行根目录下的 `disable.bat`。
2. 弹出 UAC 用户账户控制提示时点击“是”（脚本会自动请求管理员权限）。
3. 等待控制台输出绿色提示 `[成功] Windows 更新已彻底关闭` 即可。

### 恢复更新
1. 直接双击运行根目录下的 `restore.bat`。
2. 弹出 UAC 用户账户控制提示时点击“是”。
3. 等待控制台输出 `[成功] Windows 更新功能已完全复原！`，重启计算机即可正常接收官方更新。

---

## ⚠️ 注意事项

* 本工具彻底禁用了系统的自动更新通道，包含系统质量补丁、驱动更新及 Defender 病毒库的自动在线获取。
* 适合用于稳定工作机、渲染机、游戏机或工控机，防止工作或游戏时遭遇意外重启或负优化。
* 若后续需要手动更新系统或安装可选功能包（如 WSL、.NET 3.5 等），请先运行 `restore.bat` 恢复后再进行操作。

---

## 📄 开源许可

本项目基于 [MIT License](LICENSE) 开源。
