# ============================================================
# install-client.ps1 — GUI-инсталлер клиентской части реалма «Эхо Пустоты»
# Windows (WinForms). Копирует патчи и устанавливает аддоны в каталог
# клиента WoW 3.3.5a, сверяет контрольные суммы, чистит кэш, правит realmlist.
#
# Запуск:
#   powershell -ExecutionPolicy Bypass -File install-client.ps1
#   (или двойной клик по .bat рядом)
#
# Источник файлов — каталог dist/ этого инсталлера:
#   dist/manifest.json   — манифест (патчи, sha256, realmlist, cacheDirs)
#   dist/patch-x.mpq     — DBC-патч + встроенный аддон AIO
#   dist/patch-Z.mpq     — кастомные карты
#   dist/addons/…        — аддоны (zip или каталоги)
#
# Генерация dist/ (build-installer.ps1) копирует файлы из client/
# и модулей. Инсталлер НЕ требует веб-хостинг: вся доставка локальная.
# ============================================================

param(
    [switch]$Silent,
    [string]$WowDir = $null
)

$ErrorActionPreference = "Stop"

# --- Адрес запуска ---
$Script:DistDir = Join-Path $PSScriptRoot "dist"

function Get-InstallerManifest {
    $mf = Join-Path $Script:DistDir "manifest.json"
    if (-not (Test-Path $mf)) {
        throw "Манифест не найден: $mf`nСначала соберите комплект:  .\build-installer.ps1"
    }
    return Get-Content $mf -Raw -Encoding UTF8 | ConvertFrom-Json
}

# Пресеты путей WoW (наиболее частые каталоги установки 3.3.5a)
$WowDirs = @(
    $env:ProgramFiles + "\World of Warcraft",
    "E:\World of Warcraft 3.3.5a (ruRu enGB enUs) (12340)",
    "C:\Games\WoW335a",
    "C:\WoW"
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Test-WowDir([string]$dir) {
    return (Test-Path (Join-Path $dir "Wow.exe"))
}

# ============================================================
# Логика установки (без UI — переиспользуется и в --Silent)
# ============================================================
function Install-ToClient {
    param(
        [string]$WowDir,
        [string]$LogPath,
        $Manifest,
        [hashtable]$Components   # имя -> bool
    )

    $log = [System.Collections.Generic.List[string]]::new()
    $log.Add("=== Установка «Эхо Пустоты» $(Get-Date -Format 'yyyy-MM-dd HH:mm') ===")
    $log.Add("Клиент: $WowDir")
    try { $log.Add("Манифест: реалм '$($Manifest.realm)' v$($Manifest.version), файлов: $($Manifest.files.Count)") }
    catch { $log.Add("Манифест: <не прочитан>") }

    $destData = Join-Path $WowDir "Data"
    $destAddons = Join-Path $WowDir "Interface\AddOns"

    # --- 1. Патчи из манифеста (patch-x, addons/*) ---
    foreach ($file in $Manifest.files) {
        $entry = $file.path            # напр. "patch-x.mpq" | "addons/AzerothEcho.zip"
        $component = "patch-x"; if ($file.path -match "patch-Z") { $component = "patch-z" }
        elseif ($file.path -match "addons|AddOns") { $component = "addons" }
        if ($Components.ContainsKey($component) -and -not $Components[$component]) {
            $log.Add("Пропуск (выкл.): $entry")
            continue
        }

        $src = Join-Path $Script:DistDir $entry
        if (-not (Test-Path $src)) {
            $log.Add("  !")  # placeholder
            $log.RemoveAt($log.Count - 1)
            $log.Add("  НЕТ ФАЙЛА В KОМПЛЕКТЕ: $entry — пропуск")
            continue
        }

        $isZip = $file.destination -match "\.zip$"
        if ($isZip) {
            # Аддон-архив без вложенного каталога -> распаковать в Interface/AddOns/<Имя>/... 
            $zipName = [System.IO.Path]::GetFileNameWithoutExtension($file.destination)
            $dirName = [System.IO.Path]::GetFileNameWithoutExtension($entry)
            $target = Join-Path $destAddons $dirName
            if (-not (Test-Path $destAddons)) { New-Item -ItemType Directory -Path $destAddons -Force | Out-Null }
            # Проверка дистрибутива
            $h = (Get-FileHash -Path $src -Algorithm SHA256).Hash.ToLower()
            if ($file.sha256 -and $file.sha256 -ne "PLACEHOLDER_REPLACE_AFTER_BUILD" -and $h -ne $file.sha256.ToLower()) {
                $log.Add("  ОШИБКА sha256: $entry")
                continue
            }
            # Очистка старой версии аддона
            if (Test-Path $target) { Remove-Item -Path $target -Recurse -Force }
            Expand-Archive -Path $src -DestinationPath $target -Force
            $log.Add("Аддон: $dirName  ->  $($file.destination)  [OK]")
        } else {
            # Патч MPQ -> Data/
            if (-not (Test-Path $destData)) { New-Item -ItemType Directory -Path $destData -Force | Out-Null }
            $dest = Join-Path $destData ([System.IO.Path]::GetFileName($file.destination))
            # Сверка sha256 (если уже стоит)
            $needCopy = $true
            if (Test-Path $dest) {
                $h = (Get-FileHash -Path $dest -Algorithm SHA256).Hash.ToLower()
                if ($file.sha256 -and $h -eq $file.sha256.ToLower()) {
                    $needCopy = $false
                    $log.Add("OK (актуален): $entry")
                }
            }
            if ($needCopy) {
                Copy-Item -Path $src -Destination $dest -Force
                $h = (Get-FileHash -Path $dest -Algorithm SHA256).Hash.ToLower()
                if ($file.sha256 -and $file.sha256 -ne "PLACEHOLDER_REPLACE_AFTER_BUILD" -and $h -ne $file.sha256.ToLower()) {
                    $log.Add("  ОШИБКА sha256 после копирования: $entry")
                } else {
                    $log.Add("Патч: $entry  ->  Data/  [OK]")
                }
            }
        }
    }

    # --- 2. Доп. аддоны из modules (Journal / ArchaeologyUI / WarbandCamp) ---
    # Источник: каталог installer/addons/ (build-installer.ps1 кладёт сюда копии из modules)
    $extraAddons = Join-Path $Script:DistDir "addons"
    if (Test-Path $extraAddons) {
        foreach ($d in (Get-ChildItem $extraAddons -Directory -ErrorAction SilentlyContinue)) {
            $target = Join-Path $destAddons $d.Name
            if (-not (Test-Path $destAddons)) { New-Item -ItemType Directory -Path $destAddons -Force | Out-Null }
            if (Test-Path $target) { Remove-Item -Path $target -Recurse -Force }
            Copy-Item -Path $d.FullName -Destination $destAddons -Recurse -Force
            $log.Add("Аддон модуля: $($d.Name)  [OK]")
        }
        # также одиночные файлы (напр. zip) — не глубоко, только прямой каталог dist/addons
        foreach ($f in (Get-ChildItem $extraAddons -File -ErrorAction SilentlyContinue)) {
            $log.Add("(dist/addons: файл $($f.Name) — пропущен, ожидается каталог аддона)")
        }
    }

    # --- 3. Очистка кэша клиента ---
    foreach ($cacheDir in $Manifest.cacheDirs) {
        $cachePath = Join-Path $WowDir $cacheDir
        if (Test-Path $cachePath) {
            Remove-Item -Path $cachePath -Recurse -Force
            $log.Add("Кэш очищен: $cacheDir")
        } else {
            $log.Add("Кэш (нет): $cacheDir")
        }
    }

    # --- 4. Realmlist ---
    $realmlistCandidates = @(
        (Join-Path $WowDir "Data\enGB\realmlist.wtf"),
        (Join-Path $WowDir "Data\enUS\realmlist.wtf"),
        (Join-Path $WowDir "Data\ruRU\realmlist.wtf")
    )
    $realmlist = $realmlistCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    $realmlistValue = $Manifest.realmlist
    if ($realmlist) {
        Set-Content -Path $realmlist -Value "set realmlist $realmlistValue" -Encoding ASCII
        $log.Add("Realmlist: $realmlist  ->  $realmlistValue")
    } else {
        $log.Add("ВНИМАНИЕ: realmlist.wtf не найден — пропишите реалм вручную.")
    }

    # --- 5. Журнал ---
    if ($LogPath) {
        $log.Add("=== Готово. $(Get-Date -Format 'HH:mm:ss') ===")
        $log | Set-Content -Path $LogPath -Encoding UTF8
    }

    return $log
}

# ============================================================
# GUI (WinForms)
# ============================================================
function Show-Gui {
    $Manifest = $null
    try { $Manifest = Get-InstallerManifest } catch { $Script:ManifestError = $_.Exception.Message }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Эхо Пустоты — установка клиента"
    $form.Width = 640
    $form.Height = 620
    $form.StartPosition = "CenterScreen"
    $form.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false

    # --- Заголовок ---
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "Установка клиентской части реалма" 
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
    $lbl.Location = New-Object System.Drawing.Point(15, 12)
    $lbl.AutoSize = $true
    $form.Controls.Add($lbl)

    # Статус манифеста
    $lblMf = New-Object System.Windows.Forms.Label
    if ($Manifest) {
        $lblMf.Text = "Манифест: реалм «$($Manifest.realm)», версия $($Manifest.version), файлов: $($Manifest.files.Count)"
        $lblMf.ForeColor = [System.Drawing.Color]::Green
    } else {
        $lblMf.Text = "Манифест не найден: $($Script:ManifestError)"
        $lblMf.ForeColor = [System.Drawing.Color]::Red
    }
    $lblMf.Location = New-Object System.Drawing.Point(15, 42)
    $lblMf.AutoSize = $true
    $form.Controls.Add($lblMf)

    # --- Каталог клиента ---
    $lblDir = New-Object System.Windows.Forms.Label
    $lblDir.Text = "Каталог игры (с Wow.exe):"
    $lblDir.Location = New-Object System.Drawing.Point(15, 75)
    $lblDir.AutoSize = $true
    $form.Controls.Add($lblDir)

    $txtDir = New-Object System.Windows.Forms.TextBox
    $txtDir.Location = New-Object System.Drawing.Point(15, 97)
    $txtDir.Width = 480
    $autoWoW = $WowDirs | Where-Object { Test-WowDir $_ } | Select-Object -First 1
    if ($autoWoW) { $txtDir.Text = $autoWoW }
    $form.Controls.Add($txtDir)

    $btnBrowse = New-Object System.Windows.Forms.Button
    $btnBrowse.Text = "Обзор..."
    $btnBrowse.Location = New-Object System.Drawing.Point(505, 95)
    $btnBrowse.Width = 105
    $form.Controls.Add($btnBrowse)

    $lblDirStatus = New-Object System.Windows.Forms.Label
    $lblDirStatus.Text = ""
    $lblDirStatus.Location = New-Object System.Drawing.Point(15, 122)
    $lblDirStatus.AutoSize = $true  # set below
    $form.Controls.Add($lblDirStatus)

    # --- Компоненты ---
    $grp = New-Object System.Windows.Forms.GroupBox
    $grp.Text = "Компоненты"
    $grp.Location = New-Object System.Drawing.Point(15, 160)
    $grp.Width = 595
    $grp.Height = 180
    $form.Controls.Add($grp)

    $Components = @{ "patch-x" = $true; "patch-z" = $true; "addons" = $true; "modules" = $true }
    $chkDefinitions = @(
        @{ Key = "patch-x"; Text = "Патч patch-x.mpq (DBC, спеллы, AIO)" },
        @{ Key = "patch-z"; Text = "Патч patch-z.mpq (кастомные карты)" },
        @{ Key = "addons"; Text = "AzerothEcho (панель реалма, аддон)" },
        @{ Key = "modules"; Text = "Аддоны модулей (Journal, ArchaeologyUI, WarbandCamp)" }
    )
    $chkBoxes = @{}
    $chkY = 25
    foreach ($def in $chkDefinitions) {
        $chk = New-Object System.Windows.Forms.CheckBox
        $chk.Text = $def.Text
        $chk.Checked = $Components[$def.Key]
        $chk.Location = New-Object System.Drawing.Point(16, $chkY)
        $chk.AutoSize = $true
        $chk.Add_CheckedChanged({
            $Components[$def.Key] = $chk.Checked
        })
        $grp.Controls.Add($chk)
        $chkBoxes[$def.Key] = $chk
        $chkY += 28
    }

    # --- Журнал ---
    $lblLog = New-Object System.Windows.Forms.Label
    $lblLog.Text = "Журнал установки:"
    $lblLog.Location = New-Object System.Drawing.Point(15, 350)
    $lblLog.AutoSize = $true
    $form.Controls.Add($lblLog)

    $txtLog = New-Object System.Windows.Forms.TextBox
    $txtLog.Multiline = $true
    $txtLog.ScrollBars = "Vertical"
    $txtLog.ReadOnly = $true
    $txtLog.Location = New-Object System.Drawing.Point(15, 372)
    $txtLog.Size = New-Object System.Drawing.Size(595, 140)
    $txtLog.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $txtLog.ForeColor = [System.Drawing.Color]::LimeGreen
    $form.Controls.Add($txtLog)

    # --- Кнопки ---
    $btnInstall = New-Object System.Windows.Forms.Button
    $btnInstall.Text = "Установить"
    $btnInstall.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 60)
    $btnInstall.ForeColor = [System.Drawing.Color]::White
    $btnInstall.Size = New-Object System.Drawing.Size(120, 36)
    $btnInstall.Location = New-Object System.Drawing.Point(370, 525)
    $form.Controls.Add($btnInstall)

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = "Закрыть"
    $btnOk.Size = New-Object System.Drawing.Size(90, 36)
    $btnOk.Location = New-Object System.Drawing.Point(505, 525)
    $form.Controls.Add($btnOk)

    # --- Логика ---
    function Write-LogBox { param([string]$m) $txtLog.AppendText("$m`r`n") }

    function Update-DirStatus {
        $dir = $txtDir.Text.Trim()
        if (Test-WowDir $dir) {
            $lblDirStatus.Text = "✓ Wow.exe найден"
            $lblDirStatus.ForeColor = [System.Drawing.Color]::Green
        } else {
            $lblDirStatus.Text = "✗ Wow.exe не найден — выберите корень клиента"
            $lblDirStatus.ForeColor = [System.Drawing.Color]::Red
        }
    }
    Update-DirStatus

    $btnBrowse.Add_Click({
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        $dlg.Description = "Выберите папку клиента World of Warcraft 3.3.5a"
        if ($txtDir.Text -and (Test-Path $txtDir.Text)) { $dlg.SelectedPath = $txtDir.Text }
        if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $txtDir.Text = $dlg.SelectedPath
            Update-DirStatus
        }
    })

    $txtDir.Add_TextChanged({ Update-DirStatus })

    $btnInstall.Add_Click({
        $btnInstall.Enabled = $false
        $txtLog.Clear()
        Write-LogBox "Запуск установки..."
        if (-not $Manifest) { Write-LogBox "ОШИБКА: манифест не найден"; $btnInstall.Enabled = $true; return }
        $dir = $txtDir.Text.Trim()
        if (-not (Test-WowDir $dir)) {
            Write-LogBox "ОШИБКА: укажите корректный каталог клиента (Wow.exe)."
            $btnInstall.Enabled = $true
            return
        }
        $logPath = Join-Path $env:TEMP ("echo-void-install-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
        try {
            $res = Install-ToClient -WowDir $dir -LogPath $logPath -Manifest $Manifest -Components $Components
            foreach ($line in $res) { Write-LogBox $line }
            Write-LogBox ""
            Write-LogBox "Журнал: $logPath"
        } catch {
            Write-LogBox "ОШИБКА: $($_.Exception.Message)"
        }
        $btnInstall.Enabled = $true
    })

    $btnOk.Add_Click({ $form.Close() })

    [void]$form.ShowDialog()
}

# ============================================================
# Entry
# ============================================================
if ($Silent) {
    # Без GUI: установка в указанный -WowDir (или первый найденный каталог).
    $Manifest = Get-InstallerManifest
    $dir = $WowDir
    if (-not $dir) { $dir = $WowDirs | Where-Object { Test-WowDir $_ } | Select-Object -First 1 }
    if (-not $dir -or -not (Test-WowDir $dir)) {
        Write-Host "[ОШИБКА] Каталог клиента не найден. Укажите -WowDir <путь> (должен содержать Wow.exe)." -ForegroundColor Red
        exit 1
    }
    $Components = @{ "patch-x" = $true; "patch-z" = $true; "addons" = $true; "modules" = $true }
    Install-ToClient -WowDir $dir -LogPath (Join-Path $env:TEMP "echo-void-install-silent.log") -Manifest $Manifest -Components $Components
    Write-Host "Silent install done."
    exit 0
} else {
    Show-Gui
}