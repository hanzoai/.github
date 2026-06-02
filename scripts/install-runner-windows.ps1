# install-runner-windows.ps1 — Windows-native GitHub Actions runner installer.

param(
    [Parameter(Mandatory=$true)][string]$Org,
    [Parameter(Mandatory=$true)][string]$RunnerHost,
    [string]$RunnerVer = "2.321.0"
)

$ErrorActionPreference = "Stop"

if (-not $env:GH_RUNNER_TOKEN) {
    Write-Error "GH_RUNNER_TOKEN env var required"
    exit 2
}

$arch = $env:PROCESSOR_ARCHITECTURE.ToLower()
switch ($arch) {
    "amd64" { $pkgArch = "x64";   $labelArch = "amd64" }
    "arm64" { $pkgArch = "arm64"; $labelArch = "arm64" }
    default { Write-Error "unsupported arch: $arch"; exit 3 }
}

# Windows runners use a -windows suffix so Linux/WSL runners on the same
# host can coexist (they register as `<host>-<org>-<arch>` without suffix).
$RunnerName = "$RunnerHost-$Org-$labelArch-windows"
$Labels = "self-hosted,$RunnerName,$RunnerHost-$Org-windows,$Org-$labelArch,$Org-windows-$labelArch,$Org-windows"
$InstallDir = "$env:USERPROFILE\actions-runner-$Org-$RunnerHost-windows"
$RunnerUrl = "https://github.com/$Org"
$ServiceName = "actions.runner.$Org.$RunnerName"

$pkg = "actions-runner-win-$pkgArch-$RunnerVer.zip"
$pkgUrl = "https://github.com/actions/runner/releases/download/v$RunnerVer/$pkg"

Write-Host "installing windows runner: $RunnerName for $Org at $InstallDir"

# Stop existing service
$svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($svc) {
    Write-Host "stopping existing service $ServiceName"
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    # Use config.cmd --remove to deregister + delete service
    if (Test-Path "$InstallDir\config.cmd") {
        Push-Location $InstallDir
        & .\config.cmd remove --token $env:GH_RUNNER_TOKEN 2>$null
        Pop-Location
    }
}

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Set-Location $InstallDir

if (-not (Test-Path "$InstallDir\$pkg")) {
    Write-Host "downloading $pkg"
    Invoke-WebRequest -Uri $pkgUrl -OutFile "$InstallDir\$pkg"
}

Write-Host "extracting"
Expand-Archive -Path "$InstallDir\$pkg" -DestinationPath $InstallDir -Force

# Configure runner (no service flag — service install requires admin)
Write-Host "configuring runner"
& .\config.cmd `
    --unattended `
    --replace `
    --url $RunnerUrl `
    --token $env:GH_RUNNER_TOKEN `
    --name $RunnerName `
    --labels $Labels `
    --work "_work"

# Register as Scheduled Task at logon (no admin needed when scoped to current user)
$TaskName = "actions-runner-$Org-$RunnerHost"
Write-Host "registering Scheduled Task: $TaskName"

# Remove existing if any
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

$action  = New-ScheduledTaskAction -Execute "$InstallDir\run.cmd" -WorkingDirectory $InstallDir
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartCount 999 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -ExecutionTimeLimit (New-TimeSpan -Days 0)

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -RunLevel Limited

# Start now
Start-ScheduledTask -TaskName $TaskName

Write-Host "done. runner $RunnerName running as Scheduled Task '$TaskName'"
Get-ScheduledTask -TaskName $TaskName | Select-Object TaskName, State
