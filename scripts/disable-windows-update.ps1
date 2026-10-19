<#
.SYNOPSIS
    彻底永久禁用 Windows 10/11 更新（兼容家庭版与专业版）
.DESCRIPTION
    1. 停止并禁用 Windows Update 核心及依赖服务（wuauserv, WaaSMedicSvc, UsoSvc, dosvc, BITS）
    2. 接管权限并禁用所有关联计划任务（UpdateOrchestrator, WindowsUpdate, WaaSMedic, InstallService）
    3. 写入注册表组策略拦截更新检测、强制重启、驱动自动安装与应用商店后台下载
    4. 清除服务失败自动恢复动作，防止服务复活
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# 确保以管理员权限运行
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "此脚本必须以管理员身份运行！请右键以管理员身份运行 PowerShell。"
    exit 1
}

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "   Windows Update Disabler - 彻底禁用更新    " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 1. 停止并禁用核心系统服务
Write-Host "[1/4] 正在停止并禁用更新相关服务..." -ForegroundColor Yellow
$services = @("wuauserv", "WaaSMedicSvc", "UsoSvc", "dosvc", "BITS")

foreach ($svc in $services) {
    try {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        # 通过注册表修改启动类型为 4 (Disabled)，避免权限受限报错
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$svc" -Name "Start" -Value 4 -ErrorAction Stop
        # 清除崩溃或失败恢复重试机制
        cmd.exe /c "sc failure $svc reset= 0 actions= >nul 2>&1"
        Write-Host "  [√] 成功禁用服务: $svc" -ForegroundColor Green
    } catch {
        Write-Warning "  [!] 处理服务 $svc 时遇到警告: $($_.Exception.Message)"
    }
}

# 2. 写入注册表强制策略
Write-Host "[2/4] 正在配置注册表系统策略..." -ForegroundColor Yellow
$wuPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$auPolicyPath = "$wuPolicyPath\AU"
$storePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"
$driverSearchPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching"

foreach ($path in @($wuPolicyPath, $auPolicyPath, $storePolicyPath, $driverSearchPath)) {
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }
}

# 禁用 Windows Update 访问与驱动静默安装
Set-ItemProperty -Path $wuPolicyPath -Name "DisableWindowsUpdateAccess" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $wuPolicyPath -Name "SetDisableUXWUAccess" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $wuPolicyPath -Name "ExcludeWUDriversInQualityUpdate" -Value 1 -Type DWord -Force

# 禁用自动更新检测及通知
Set-ItemProperty -Path $auPolicyPath -Name "NoAutoUpdate" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $auPolicyPath -Name "AUOptions" -Value 1 -Type DWord -Force

# 禁用驱动自动搜索联网更新
Set-ItemProperty -Path $driverSearchPath -Name "SearchOrderConfig" -Value 0 -Type DWord -Force

# 禁用应用商店应用自动静默更新
Set-ItemProperty -Path $storePolicyPath -Name "AutoDownload" -Value 2 -Type DWord -Force
Write-Host "  [√] 注册表策略已全部写入并锁定" -ForegroundColor Green

# 3. 夺权并彻底禁用关联计划任务（防死灰复燃）
Write-Host "[3/4] 正在夺权并禁用后台唤醒计划任务..." -ForegroundColor Yellow
$taskFolders = @(
    "C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator",
    "C:\Windows\System32\Tasks\Microsoft\Windows\WindowsUpdate",
    "C:\Windows\System32\Tasks\Microsoft\Windows\WaaSMedic"
)

foreach ($folder in $taskFolders) {
    if (Test-Path $folder) {
        cmd.exe /c "takeown /f `"$folder`" /a /r /d y >nul 2>&1"
        cmd.exe /c "icacls `"$folder`" /grant Administrators:F /t >nul 2>&1"
    }
}

$taskPaths = @(
    "\Microsoft\Windows\UpdateOrchestrator\",
    "\Microsoft\Windows\WindowsUpdate\",
    "\Microsoft\Windows\WaaSMedic\",
    "\Microsoft\Windows\InstallService\"
)

foreach ($tp in $taskPaths) {
    $tasks = Get-ScheduledTask -TaskPath $tp -ErrorAction SilentlyContinue
    foreach ($task in $tasks) {
        try {
            Disable-ScheduledTask -TaskPath $tp -TaskName $task.TaskName -ErrorAction SilentlyContinue | Out-Null
        } catch {}
    }
}
Write-Host "  [√] 所有更新唤醒任务已全部禁用" -ForegroundColor Green

# 4. 验证最终状态
Write-Host "[4/4] 验证配置状态..." -ForegroundColor Yellow
$statusList = Get-Service -Name $services | Select-Object Name, Status, StartType
$statusList | Format-Table -AutoSize

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  [成功] Windows 更新已彻底关闭，不再骚扰！   " -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan
