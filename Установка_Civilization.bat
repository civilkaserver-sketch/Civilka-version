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
    if (Test-Path (Join-Path $scriptDir "versions\Civilization\Civilization.json")) {
        $sourceDir = $scriptDir
        Write-Host "[+] Локальные файлы сборки найдены." -ForegroundColor Green
    } elseif (Test-Path "$env:TEMP\Civilka-version\versions\Civilization\Civilization.json") {
        $sourceDir = "$env:TEMP\Civilka-version"
        Write-Host "[+] Найдена сборка в кэше: $sourceDir" -ForegroundColor Green
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
            if ($cloneRes.ExitCode -eq 0 -and (Test-Path (Join-Path $targetWork "versions\Civilization\Civilization.json"))) {
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
                if (Test-Path (Join-Path $unpacked "versions\Civilization\Civilization.json")) {
                    $sourceDir = $unpacked
                    $downloaded = $true
                    Write-Host "[+] Сборка успешно распакована!" -ForegroundColor Green
                }
            }
        }

        if (-not $downloaded) {
            throw "Не удалось загрузить файлы сборки с GitHub! Проверьте интернет."
        }
    }

    Write-Host ""
    Write-Host "[*] Поиск активной папки Minecraft..." -ForegroundColor Cyan

    $detectedMc = $null

    # 1. Проверяем настройки TLauncher (самый точный способ для TLauncher пользователей)
    $tlProps = Join-Path $env:APPDATA ".tlauncher\tlauncher-2.0.properties"
    if (Test-Path $tlProps) {
        $lines = Get-Content $tlProps -Encoding utf8
        foreach ($l in $lines) {
            if ($l -match "^minecraft\.gamedir=(.+)$") {
                $raw = $matches[1].Replace("\:", ":").Replace("\\", "\").Trim()
                if (Test-Path $raw) {
                    $detectedMc = $raw
                    Write-Host "[+] Найдена папка Minecraft из настроек TLauncher!" -ForegroundColor Green
                    break
                }
            }
        }
    }

    # 2. Если TLauncher не указал путь, проверяем стандартные папки
    if (-not $detectedMc) {
        $candidates = @(
            "E:\Games\.minecraft",
            "D:\Games\.minecraft",
            "C:\Games\.minecraft",
            (Join-Path $env:APPDATA ".minecraft"),
            "D:\.minecraft",
            "E:\.minecraft"
        )
        foreach ($c in $candidates) {
            if (Test-Path $c) {
                $detectedMc = $c
                break
            }
        }
    }

    if ($detectedMc) {
        Write-Host "[+] Папка Minecraft: " -NoNewline -ForegroundColor Green
        Write-Host "$detectedMc" -ForegroundColor White
        Write-Host ""
        Write-Host "Нажмите ENTER для установки в эту папку," -ForegroundColor Yellow
        Write-Host "или введите другой путь вручную:" -ForegroundColor Yellow
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
    Write-Host "Установка изолированной сборки Civilization в: $mcDir" -ForegroundColor Cyan
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host ""

    # 1. Библиотеки Forge
    Write-Host "[1/2] Установка библиотек Forge (134 файла) в .minecraft/libraries..." -ForegroundColor Yellow
    $libSrc = Join-Path $sourceDir "libraries"
    $libDst = Join-Path $mcDir "libraries"
    if (Test-Path $libSrc) {
        if (-not (Test-Path $libDst)) { New-Item -ItemType Directory -Path $libDst -Force | Out-Null }
        Copy-Item -Recurse -Force (Join-Path $libSrc "*") $libDst
    }

    # 2. Изолированная версия Civilization
    Write-Host "[2/2] Установка версии в .minecraft/versions/Civilization..." -ForegroundColor Yellow
    Write-Host "      - Все 13 модов (playertrading, simplemenu, OptiFine, Xaeros)" -ForegroundColor Gray
    Write-Host "      - Ресурспаки и артефакты (Звездный оберег, Кровавый топор, Поступь тени)" -ForegroundColor Gray
    Write-Host "      - Шейдерпаки" -ForegroundColor Gray
    Write-Host "      - Меню SimpleMenu (фоны, логотипы, иконки)" -ForegroundColor Gray
    Write-Host "      - Список серверов (servers.dat с сервером Civilization)" -ForegroundColor Gray
    $civSrc = Join-Path $sourceDir "versions\Civilization"
    $civDst = Join-Path $mcDir "versions\Civilization"
    if (-not (Test-Path $civDst)) { New-Item -ItemType Directory -Path $civDst -Force | Out-Null }
    Copy-Item -Recurse -Force (Join-Path $civSrc "*") $civDst

    # Регистрация профиля в launcher_profiles.json и TlauncherProfiles.json
    $profileConfigs = @("launcher_profiles.json", "TlauncherProfiles.json")
    foreach ($pCfg in $profileConfigs) {
        $lpPath = Join-Path $mcDir $pCfg
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
                    lastVersionId = "Civilization"
                    name = "Civilization"
                    type = "custom"
                    gameDir = $civDst
                }
                $json.profiles | Add-Member -MemberType NoteProperty -Name "Civilization" -Value $civ -Force
                $json | ConvertTo-Json -Depth 10 | Set-Content $lpPath -Encoding utf8
                Write-Host "[+] Профиль 'Civilization' зарегистрирован в $pCfg" -ForegroundColor Green
            } catch {
                Write-Host "[!] Заметка: не удалось обновить $pCfg" -ForegroundColor Gray
            }
        }
    }

    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host "               УСТАНОВКА УСПЕШНО ЗАВЕРШЕНА!                       " -ForegroundColor Green
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Папка сборки: $civDst" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Что делать дальше:" -ForegroundColor Cyan
    Write-Host "1. Откройте лаунчер (TLauncher, Legacy, Minecraft Launcher)." -ForegroundColor White
    Write-Host "2. В списке версий выберите: 'Civilization'." -ForegroundColor White
    Write-Host "3. Нажмите 'Войти в игру'!" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor Red
    Write-Host "[ОШИБКА] $_" -ForegroundColor Red
    Write-Host "==================================================================" -ForegroundColor Red
    Write-Host ""
}

Read-Host "Нажмите ENTER для выхода"
