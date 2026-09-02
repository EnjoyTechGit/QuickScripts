# Check In
$wingetExe = Get-ChildItem -Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe" -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $wingetExe) {
    Write-Host "WinGet not found. Installing..." -ForegroundColor Yellow
    
    if (-not (Test-Path -Path "C:\Public")) {
        New-Item -Path "C:\Public" -ItemType Directory -Force | Out-Null
    }
    
    $wingetUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    Invoke-WebRequest -Uri $wingetUrl -OutFile "C:\Public\Microsoft.DesktopAppInstaller.msixbundle" -UserAgent "Mozilla/5.0"
    Add-AppxProvisionedPackage -Online -PackagePath "C:\Public\Microsoft.DesktopAppInstaller.msixbundle" -SkipLicense | Out-Null
    
    $wingetExe = (Get-ChildItem -Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe" | Select-Object -First 1).FullName
} else {
    $wingetExe = $wingetExe.FullName
    Write-Host "WinGet is already installed." -ForegroundColor Green
}

# Boarding
$regPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$installedApp = Get-ItemProperty -Path $regPaths -ErrorAction SilentlyContinue | 
    Where-Object { $_.DisplayName -like "*eParakst*" } | 
    Select-Object -First 1

$oldVersion = if ($installedApp) { $installedApp.DisplayVersion } else { $null }

if ($oldVersion) {
    Write-Host "Currently installed version: $oldVersion" -ForegroundColor Cyan
} else {
    Write-Host "eParakst is not currently installed." -ForegroundColor Yellow
}

# InFlight
Write-Host "Checking WinGet repository for eParakst..." -ForegroundColor Cyan
$wingetCheck = & $wingetExe show -e --id eParaksts.eParakstitajs --accept-source-agreements 2>&1 | Out-String

# Service refreshments
if (-not $oldVersion) {
    Write-Host "Proceeding with initial installation of eParaksts.eParakstitajs..." -ForegroundColor Yellow
    & $wingetExe install -e --id eParaksts.eParakstitajs --silent --accept-package-agreements --accept-source-agreements
} else {
    Write-Host "Running update check/install via WinGet..." -ForegroundColor Yellow
    & $wingetExe upgrade -e --id eParaksts.eParakstitajs --silent --accept-package-agreements --accept-source-agreements
}

# Landing
$newApp = Get-ItemProperty -Path $regPaths -ErrorAction SilentlyContinue | 
    Where-Object { $_.DisplayName -like "*eParakst*" } | 
    Select-Object -First 1

$newVersion = if ($newApp) { $newApp.DisplayVersion } else { $null }

# End Of The Line
Write-Host "`n========================================" -ForegroundColor Gray
if (-not $oldVersion -and $newVersion) {
    Write-Host "SUCCESS: Installed eParakst v$newVersion complete." -ForegroundColor Green
} elseif ($oldVersion -and $newVersion -and ([version]$newVersion -gt [version]$oldVersion)) {
    Write-Host "SUCCESS: Updated eParakst from v$oldVersion to v$newVersion complete." -ForegroundColor Green
} elseif ($oldVersion -and $newVersion -and $oldVersion -eq $newVersion) {
    Write-Host "INFO: eParakst is already at the latest version (v$newVersion)." -ForegroundColor Cyan
} else {
    Write-Host "ERROR: eParakst installation/update failed or version could not be detected." -ForegroundColor Red
}
Write-Host "========================================`n"