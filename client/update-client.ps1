# ============================================================
# update-client.ps1 — Лаунчер-минимум реалма «Эхо Пустоты»
# Подход Waloria (docs/client-patch.md ч. 4a):
#   сверка manifest.json -> докачка отличий -> очистка Cache ->
#   realmlist -> запуск клиента.
#
# Использование:
#   powershell -ExecutionPolicy Bypass -File update-client.ps1 ^
#     -WowDir "C:\Games\WoW335a" ^
#     -PatchUrl "https://example.com/patches"
#
#   -WowDir    каталог клиента 3.3.5a (содержит Wow.exe)
#   -PatchUrl  URL веб-каталога патчей (там лежат manifest.json
#              и файлы из client/manifest.json)
# ============================================================
param(
    [Parameter(Mandatory = $true)]
    [string]$WowDir,

    [Parameter(Mandatory = $true)]
    [string]$PatchUrl
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Write-Log([string]$msg) {
    Write-Host "[EchoOfTheVoid] $msg"
}

function Write-Fail([string]$msg) {
    Write-Host "[EchoOfTheVoid][ОШИБКА] $msg" -ForegroundColor Red
    exit 1
}

# ---- Проверка каталога клиента ----
if (-not (Test-Path (Join-Path $WowDir "Wow.exe"))) {
    Write-Fail "Wow.exe не найден в '$WowDir' — укажите корень клиента 3.3.5a."
}
Write-Log "Клиент: $WowDir"

# ---- Загрузка манифеста ----
$manifestUrl = "$PatchUrl/manifest.json"
Write-Log "Загрузка манифеста: $manifestUrl ..."
try {
    $manifest = Invoke-RestMethod -Uri $manifestUrl -UseBasicParsing
} catch {
    Write-Fail "Манифест недоступен: $($_.Exception.Message)"
}
Write-Log "Манифест: реалм '$($manifest.realm)', версия $($manifest.version), файлов: $($manifest.files.Count)"

# ---- Сверка и докачка файлов ----
$changed = 0
foreach ($file in $manifest.files) {
    $destPath = Join-Path $WowDir $file.destination

    $needDownload = $true
    if (Test-Path $destPath) {
        $localHash = (Get-FileHash -Path $destPath -Algorithm SHA256).Hash.ToLower()
        if ($localHash -eq $file.sha256.ToLower()) {
            Write-Log "ОК  $($file.destination) (совпадает)"
            $needDownload = $false
        } else {
            Write-Log "УСТАРЕЛ  $($file.destination)"
        }
    } else {
        Write-Log "ОТСУТСТВУЕТ  $($file.destination)"
    }

    if ($needDownload) {
        $remoteUrl = "$PatchUrl/$($file.path)"
        $destDir = Split-Path $destPath -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        Write-Log "Загрузка: $remoteUrl ..."
        try {
            Invoke-WebRequest -Uri $remoteUrl -OutFile $destPath -UseBasicParsing
        } catch {
            Write-Fail "Не удалось скачать $($file.path): $($_.Exception.Message)"
        }

        # Контрольная сумма обязательных файлов
        $downloadedHash = (Get-FileHash -Path $destPath -Algorithm SHA256).Hash.ToLower()
        if ($file.sha256 -and $file.sha256 -ne "PLACEHOLDER_REPLACE_AFTER_BUILD" -and
            $file.sha256 -ne "PLACEHOLDER_REPLACE_AFTER_RELEASE" -and
            $downloadedHash -ne $file.sha256.ToLower()) {
            Write-Fail "SHA256 не совпал для $($file.destination) — файл повреждён или устарел."
        }
        $changed++
    }
}

if ($changed -eq 0) {
    Write-Log "Все файлы актуальны."
} else {
    Write-Log "Обновлено файлов: $changed"
}

# ---- Очистка кэша (клиент кэширует DBC/WDB — иначе патч не подхватится) ----
foreach ($cacheDir in $manifest.cacheDirs) {
    $cachePath = Join-Path $WowDir $cacheDir
    if (Test-Path $cachePath) {
        Write-Log "Очистка кэша: $cachePath ..."
        Remove-Item -Path $cachePath -Recurse -Force
    }
}

# ---- Realmlist ----
$realmlistPath = Join-Path $WowDir "Data\enUS\realmlist.wtf"
if (-not (Test-Path $realmlistPath)) {
    # Русская локаль клиента
    $realmlistPath = Join-Path $WowDir "Data\ruRU\realmlist.wtf"
}
if (Test-Path $realmlistPath) {
    Write-Log "Realmlist: set realmlist $($manifest.realmlist)"
    Set-Content -Path $realmlistPath -Value "set realmlist $($manifest.realmlist)" -Encoding ASCII
} else {
    Write-Log "ВНИМАНИЕ: realmlist.wtf не найден — пропущено (пропишите реалм вручную)."
}

# ---- Запуск ----
Write-Log "Запуск клиента..."
Start-Process -FilePath (Join-Path $WowDir "Wow.exe") -WorkingDirectory $WowDir
Write-Log "Готово. Приятной игры на «Эхе Пустоты»!"
