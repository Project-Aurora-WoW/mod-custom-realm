# ============================================================
# build-installer.ps1 — сборка комплекта (dist/) для GUI-инсталлера
# install-client.ps1. Копирует стабильные файлы из client/ и аддоны
# модулей (modules/*/addon/) в installer/dist/.
#
# Запуск (из каталога installer/ или с указанием --Repo):
#   powershell -ExecutionPolicy Bypass -File build-installer.ps1
# ============================================================
param(
    [string]$Repo = $null
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Каталог репозитория: по умолчанию parent от client/
if (-not $Repo) {
    $here = Split-Path $PSScriptRoot -Parent   # .../client
    $Repo = Split-Path $here -Parent            # корень репо
}
$clientDir = Join-Path $Repo "client"
$distDir   = Join-Path $PSScriptRoot "dist"
$distAddons = Join-Path $distDir "addons"

function Write-Step { param([string]$m) Write-Host "[build-installer] $m" -ForegroundColor Cyan }

# --- Проверки ---
if (-not (Test-Path (Join-Path $clientDir "manifest.json"))) {
    Write-Host "[ОШИБКА] client/manifest.json не найден: $clientDir" -ForegroundColor Red
    exit 1
}

# --- Чистка dist ---
Write-Step "Очистка dist/ ..."
if (Test-Path $distDir) { Remove-Item -Path $distDir -Recurse -Force }
New-Item -ItemType Directory -Path $distDir -Force | Out-Null
New-Item -ItemType Directory -Path $distAddons -Force | Out-Null

# --- Манифест + патчи ---
$manifest = Get-Content (Join-Path $clientDir "manifest.json") -Raw -Encoding UTF8 | ConvertFrom-Json

# Манифест — в корень dist/
Copy-Item -Path (Join-Path $clientDir "manifest.json") -Destination (Join-Path $distDir "manifest.json") -Force
Write-Step "Манифест: manifest.json"

# Патчи (из manifest.files, не-аддоны)
foreach ($file in $manifest.files) {
    $src = Join-Path $clientDir $file.path
    if (-not (Test-Path $src)) { continue }
    if ($file.path -match "addons|AddOns") {
        # zip-аддоны из манифеста
        $dstDir = Join-Path $distDir (Split-Path $file.path -Parent)
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
        Copy-Item -Path $src -Destination (Join-Path $dstDir (Split-Path $file.path -Leaf)) -Force
        Write-Step "Аддон (manifest): $($file.path)"
    } else {
        Copy-Item -Path $src -Destination $distDir -Force
        Write-Step "Файл: $($file.path)"
    }
}

# --- Аддоны модулей (modules/*/addon/) -> dist/addons/<Имя>/ ---
$modules = Get-ChildItem (Join-Path $Repo "modules") -Directory -ErrorAction SilentlyContinue
$copiedAddons = @()
foreach ($m in $modules) {
    $addonDir = Join-Path $m.FullName "addon"
    if (-not (Test-Path $addonDir)) { continue }
    foreach ($addonName in (Get-ChildItem $addonDir -Directory)) {
        $target = Join-Path $distAddons $addonName.Name
        Copy-Item -Path $addonName.FullName -Destination $target -Recurse -Force
        $copiedAddons += $addonName.Name
        Write-Step "Аддон модуля: $($addonName.Name)"
    }
}

# --- Проверка целостности (только manifest-файлы) ---
Write-Step "Проверка sha256 файлов манифеста ..."
$verifyFail = 0
foreach ($file in $manifest.files) {
    $local = Join-Path $clientDir $file.path
    if (-not (Test-Path $local)) { continue }
    $h = (Get-FileHash $local -Algorithm SHA256).Hash.ToLower()
    if ($file.sha256 -and $file.sha256 -ne "PLACEHOLDER_REPLACE_AFTER_BUILD" -and $file.sha256 -ne "PLACEHOLDER_REPLACE_AFTER_RELEASE" -and $h -ne $file.sha256.ToLower()) {
        Write-Host "  [ПРЕДУПРЕЖДЕНИЕ] sha256 не совпал: $($file.path)" -ForegroundColor Yellow
        $verifyFail++
    } else {
        Write-Host "  OK $($file.path)"
    }
}

# --- Итог ---
$totalMB = [math]::Round((Get-ChildItem $distDir -Recurse -File | Measure-Object Length -Sum).Sum / 1MB, 1)
Write-Step "Готово. dist/: аддонов модулей=$($copiedAddons.Count), sha256 fail=$verifyFail, объём=${totalMB} МБ"
Write-Step "Каталог: $distDir"
if ($verifyFail -gt 0) {
    Write-Host "[!] Есть расхождения sha256 в манифесте — проверьте файлы." -ForegroundColor Yellow
}