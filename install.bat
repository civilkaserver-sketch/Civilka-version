@echo off
title Установка Civilization 1.21.8
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f='%~f0'; $lines = [System.IO.File]::ReadAllLines($f, [System.Text.Encoding]::UTF8); $start = $false; $sb = New-Object System.Text.StringBuilder; foreach($l in $lines){ if($start){ [void]$sb.AppendLine($l) } elseif($l.StartsWith('::PS_CODE::')){ $start = $true } }; Invoke-Expression $sb.ToString()"
if %ERRORLEVEL% neq 0 (
    echo.
    echo ==================================================================
    echo [ОШИБКА] Произошла ошибка при выполнении установщика.
    echo ==================================================================
    pause
)
exit /b

::PS_CODE::
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::Title = "Установка Civilization 1.21.8"

function Print-Header {
    Clear-Host
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host "              УСТАНОВКА КЛИЕНТА CIVILIZATION 1.21.8               " -ForegroundColor Yellow
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host ""
}

try {
    Print-Header

    $scriptDir = Split-Path -Parent $f
    $sourceDir = $null

    # 1. Проверяем локальные файлы
    if (Test-Path (Join-Path $scriptDir "versions\1.21.8-forge-58.1.7")) {
        $sourceDir = $scriptDir
        Write-Host "[+] Локальные файлы сборки найдены." -ForegroundColor Green
    } elseif (Test-Path "$env:TEMP\Civilka-version\versions\1.21.8-forge-58.1.7") {
        $sourceDir = "$env:TEMP\Civilka-version"
        Write-Host "[+] Найдена ранее загруженная сборка в кэше: $sourceDir" -ForegroundColor Green
    } else {
        Write-Host "[i] Локальные файлы сборки не найдены рядом со скриптом." -ForegroundColor Cyan
        Write-Host "[i] Начинается загрузка актуальной сборки с GitHub..." -ForegroundColor Cyan
        Write-Host ""

        $targetWork = "$env:TEMP\Civilka-version"
        if (Test-Path $targetWork) { Remove-Item -Recurse -Force $targetWork -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Path $targetWork -Force | Out-Null

        $gitCmd = Get-Command git -ErrorAction SilentlyContinue
        $downloaded = $false

        if ($gitCmd) {
            Write-Host "[*] Клонирование сборки через Git (--depth 1)..." -ForegroundColor Yellow
            $cloneRes = Start-Process -FilePath "git" -ArgumentList "clone --depth 1 https://github.com/civilkaserver-sketch/Civilka-version.git `"$targetWork`"" -NoNewWindow -Wait -PassThru
            if ($cloneRes.ExitCode -eq 0 -and (Test-Path (Join-Path $targetWork "versions\1.21.8-forge-58.1.7"))) {
                $sourceDir = $targetWork
                $downloaded = $true
                Write-Host "[+] Сборка успешно загружена через Git!" -ForegroundColor Green
            }
        }

        if (-not $downloaded) {
            Write-Host "[*] Загрузка сборки через веб-запрос (zip)..." -ForegroundColor Yellow
            $zipPath = "$env:TEMP\civilka_full.zip"
            $extPath = "$env:TEMP\civilka_extracted"
            if (Test-Path $zipPath) { Remove-Item -Force $zipPath -ErrorAction SilentlyContinue }
            if (Test-Path $extPath) { Remove-Item -Recurse -Force $extPath -ErrorAction SilentlyContinue }

            $url = "https://github.com/civilkaserver-sketch/Civilka-version/archive/refs/heads/main.zip"
            
            $curlCmd = Get-Command curl.exe -ErrorAction SilentlyContinue
            if ($curlCmd) {
                & curl.exe -L --progress-bar -o $zipPath $url
            } else {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                $wc = New-Object System.Net.WebClient
                $wc.DownloadFile($url, $zipPath)
            }

            if (Test-Path $zipPath) {
                Write-Host "[*] Распаковка сборки..." -ForegroundColor Yellow
                Expand-Archive -Path $zipPath -DestinationPath $extPath -Force
                Remove-Item -Force $zipPath -ErrorAction SilentlyContinue
                
                $unpacked = Join-Path $extPath "Civilka-version-main"
                if (Test-Path (Join-Path $unpacked "versions\1.21.8-forge-58.1.7")) {
                    $sourceDir = $unpacked
                    $downloaded = $true
                    Write-Host "[+] Сборка успешно распакована!" -ForegroundColor Green
                }
            }
        }

        if (-not $downloaded) {
            throw "Не удалось загрузить файлы сборки с GitHub! Проверьте подключение к интернету."
        }
    }

    Write-Host ""
    Write-Host "[*] Поиск папки Minecraft..." -ForegroundColor Cyan

    $mcCandidates = @(
        (Join-Path $env:APPDATA ".minecraft"),
        "E:\Games\.minecraft",
        "D:\Games\.minecraft",
        "C:\Games\.minecraft",
        "D:\.minecraft",
        "E:\.minecraft"
    )

    $detectedMc = $null
    foreach ($cand in $mcCandidates) {
        if (Test-Path $cand) {
            $detectedMc = $cand
            break
        }
    }

    if ($detectedMc) {
        Write-Host "[+] Найдена папка Minecraft: " -NoNewline -ForegroundColor Green
        Write-Host "$detectedMc" -ForegroundColor White
        Write-Host ""
        Write-Host "Нажмите ENTER для установки в эту папку," -ForegroundColor Yellow
        Write-Host "или введите другой путь к .minecraft:" -ForegroundColor Yellow
        $userMc = Read-Host "Путь (или ENTER)"
        if ([string]::IsNullOrWhiteSpace($userMc)) {
            $mcDir = $detectedMc
        } else {
            $mcDir = $userMc.Trim('"', ' ')
        }
    } else {
        Write-Host "[!] Папка Minecraft не найдена автоматически." -ForegroundColor Yellow
        $mcDir = (Read-Host "Введите полный путь к папке .minecraft").Trim('"', ' ')
    }

    if (-not (Test-Path $mcDir)) {
        Write-Host "[!] Папка '$mcDir' не существует. Создать? (Y/N): " -NoNewline -ForegroundColor Yellow
        $ans = Read-Host
        if ($ans -eq "Y" -or $ans -eq "y" -or $ans -eq "Д" -or $ans -eq "д" -or [string]::IsNullOrWhiteSpace($ans)) {
            New-Item -ItemType Directory -Path $mcDir -Force | Out-Null
        } else {
            Write-Host "Установка отменена пользователем." -ForegroundColor Red
            Read-Host "Нажмите ENTER для выхода"
            return
        }
    }

    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host "Начинаем установку файлов в: $mcDir" -ForegroundColor Cyan
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host ""

    # Копирование версии
    Write-Host "[1/6] Установка версии Forge 1.21.8..." -ForegroundColor Yellow
    $vSrc = Join-Path $sourceDir "versions\1.21.8-forge-58.1.7"
    $vDst = Join-Path $mcDir "versions\1.21.8-forge-58.1.7"
    if (-not (Test-Path $vDst)) { New-Item -ItemType Directory -Path $vDst -Force | Out-Null }
    Copy-Item -Recurse -Force (Join-Path $vSrc "*") $vDst

    # Копирование библиотек
    Write-Host "[2/6] Установка библиотек Forge (134 файла)..." -ForegroundColor Yellow
    $libSrc = Join-Path $sourceDir "libraries"
    $libDst = Join-Path $mcDir "libraries"
    if (Test-Path $libSrc) {
        if (-not (Test-Path $libDst)) { New-Item -ItemType Directory -Path $libDst -Force | Out-Null }
        Copy-Item -Recurse -Force (Join-Path $libSrc "*") $libDst
    }

    # Копирование модов
    Write-Host "[3/6] Установка модов (playertrading, OptiFine, Xaeros, etc.)..." -ForegroundColor Yellow
    $modSrc = Join-Path $sourceDir "mods"
    $modDst = Join-Path $mcDir "mods"
    if (Test-Path $modSrc) {
        if (-not (Test-Path $modDst)) { New-Item -ItemType Directory -Path $modDst -Force | Out-Null }
        Copy-Item -Recurse -Force (Join-Path $modSrc "*") $modDst
    }

    # Копирование ресурспаков
    Write-Host "[4/6] Установка ресурспаков и артефактов..." -ForegroundColor Yellow
    $rpSrc = Join-Path $sourceDir "resourcepacks"
    $rpDst = Join-Path $mcDir "resourcepacks"
    if (Test-Path $rpSrc) {
        if (-not (Test-Path $rpDst)) { New-Item -ItemType Directory -Path $rpDst -Force | Out-Null }
        Copy-Item -Recurse -Force (Join-Path $rpSrc "*") $rpDst
    }

    # Копирование шейдеров
    Write-Host "[5/6] Установка шейдерпаков..." -ForegroundColor Yellow
    $spSrc = Join-Path $sourceDir "shaderpacks"
    $spDst = Join-Path $mcDir "shaderpacks"
    if (Test-Path $spSrc) {
        if (-not (Test-Path $spDst)) { New-Item -ItemType Directory -Path $spDst -Force | Out-Null }
        Copy-Item -Recurse -Force (Join-Path $spSrc "*") $spDst
    }

    # Копирование конфигов и настроек
    Write-Host "[6/6] Настройка конфигурации, шейдеров и списка серверов..." -ForegroundColor Yellow
    $cfgSrc = Join-Path $sourceDir "config"
    $cfgDst = Join-Path $mcDir "config"
    if (Test-Path $cfgSrc) {
        if (-not (Test-Path $cfgDst)) { New-Item -ItemType Directory -Path $cfgDst -Force | Out-Null }
        Copy-Item -Recurse -Force (Join-Path $cfgSrc "*") $cfgDst
    }

    foreach ($optFile in @("optionsof.txt", "optionsshaders.txt")) {
        $srcFile = Join-Path $sourceDir $optFile
        if (Test-Path $srcFile) {
            Copy-Item -Force $srcFile (Join-Path $mcDir $optFile)
        }
    }

    $srvFile = Join-Path $sourceDir "servers.dat"
    if (Test-Path $srvFile) {
        $srvDst = Join-Path $mcDir "servers.dat"
        if (-not (Test-Path $srvDst)) {
            Copy-Item -Force $srvFile $srvDst
        }
    }

    # Добавление профиля в launcher_profiles.json
    $lpPath = Join-Path $mcDir "launcher_profiles.json"
    if (Test-Path $lpPath) {
        try {
            $json = Get-Content $lpPath -Raw -Encoding utf8 | ConvertFrom-Json
            if (-not $json.profiles) {
                $json | Add-Member -MemberType NoteProperty -Name "profiles" -Value ([PSCustomObject]@{})
            }
            $civ = [PSCustomObject]@{
                created = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
                icon = "Furnace"
                lastUsed = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
                lastVersionId = "1.21.8-forge-58.1.7"
                name = "Civilization 1.21.8"
                type = "custom"
            }
            $json.profiles | Add-Member -MemberType NoteProperty -Name "Civilization" -Value $civ -Force
            $json | ConvertTo-Json -Depth 10 | Set-Content $lpPath -Encoding utf8
            Write-Host "[+] Профиль 'Civilization 1.21.8' добавлен в launcher_profiles.json" -ForegroundColor Green
        } catch {
            Write-Host "[!] Заметка: не удалось автоматически обновить launcher_profiles.json" -ForegroundColor Gray
        }
    }

    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host "               УСТАНОВКА УСПЕШНО ЗАВЕРШЕНА!                       " -ForegroundColor Green
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Что делать дальше:" -ForegroundColor Cyan
    Write-Host "1. Откройте ваш лаунчер (Minecraft Launcher, TLauncher, Legacy)." -ForegroundColor White
    Write-Host "2. Выберите версию: 'Civilization 1.21.8' (или '1.21.8-forge-58.1.7')." -ForegroundColor White
    Write-Host "3. Нажмите 'Играть' / 'Войти в игру'!" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor Red
    Write-Host "[ОШИБКА] $_" -ForegroundColor Red
    Write-Host "==================================================================" -ForegroundColor Red
    Write-Host ""
}

Read-Host "Нажмите ENTER для выхода"
