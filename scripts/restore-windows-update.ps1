<#
.SYNOPSIS
    恢复 Windows 10/11 正常更新功能
.DESCRIPTION
    1. 还原 Windows Update 相关服务的启动类型（Manual / Automatic）
    2. 移除注册表中关于禁止更新、禁止驱动、禁止商店更新的策略项
    3. 重新启用 UpdateOrchestrator、WindowsUpdate 等计划任务
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
Write-Host "   Windows Update Restore - 恢复系统更新     " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 1. 恢复服务默认启动类型
Write-Host "[1/3] 正在恢复系统服务启动类型..." -ForegroundColor Yellow
$serviceMap = @{
    "wuauserv"     = 3 # Manual
    "WaaSMedicSvc" = 3 # Manual
    "UsoSvc"       = 2 # Automatic (Delayed/Normal)
    "dosvc"        = 2 # Automatic
    "BITS"         = 3 # Manual
}

foreach ($svc in $serviceMap.Keys) {
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$svc" -Name "Start" -Value $serviceMap[$svc] -ErrorAction Stop
        Write-Host "  [√] 已恢复服务 $svc 默认启动配置" -ForegroundColor Green
    } catch {
        Write-Warning "  [!] 恢复服务 $svc 失败: $($_.Exception.Message)"
    }
}

# 2. 移除注册表拦截策略
Write-Host "[2/3] 正在清除注册表拦截策略..." -ForegroundColor Yellow
$wuPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$auPolicyPath = "$wuPolicyPath\AU"
$storePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"
$driverSearchPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching"

$policiesToRemove = @(
    @{ Path = $wuPolicyPath; Name = "DisableWindowsUpdateAccess" },
    @{ Path = $wuPolicyPath; Name = "SetDisableUXWUAccess" },
    @{ Path = $wuPolicyPath; Name = "ExcludeWUDriversInQualityUpdate" },
    @{ Path = $auPolicyPath; Name = "NoAutoUpdate" },
    @{ Path = $auPolicyPath; Name = "AUOptions" },
    @{ Path = $storePolicyPath; Name = "AutoDownload" }
)

foreach ($item in $policiesToRemove) {
    if (Test-Path $item.Path) {
        Remove-ItemProperty -Path $item.Path -Name $item.Name -ErrorAction SilentlyContinue
    }
}

if (Test-Path $driverSearchPath) {
    Set-ItemProperty -Path $driverSearchPath -Name "SearchOrderConfig" -Value 1 -ErrorAction SilentlyContinue
}
Write-Host "  [√] 注册表策略已全部复原" -ForegroundColor Green

# 3. 重新启用计划任务
Write-Host "[3/3] 正在重新启用计划任务..." -ForegroundColor Yellow
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
            Enable-ScheduledTask -TaskPath $tp -TaskName $task.TaskName -ErrorAction SilentlyContinue | Out-Null
        } catch {}
    }
}
Write-Host "  [√] 计划任务已恢复默认状态" -ForegroundColor Green

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  [成功] Windows 更新功能已完全复原！        " -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan
