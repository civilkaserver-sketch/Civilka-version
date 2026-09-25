@echo off
chcp 65001 >nul
title Установка Civilization 1.21.8
color 0B

echo ======================================================================
echo          УСТАНОВКА КЛИЕНТА CIVILIZATION 1.21.8
echo ======================================================================
echo.

set SCRIPT_DIR=%~dp0
set SCRIPT_DIR=%SCRIPT_DIR:~0,-1%

:: 1. Проверяем локальные файлы (рядом со скриптом)
if exist "%SCRIPT_DIR%\versions\1.21.8-forge-58.1.7" goto :DETECT_MC

:: Проверяем кэш во временной папке
if exist "%TEMP%\Civilka-version\versions\1.21.8-forge-58.1.7" (
    echo [+] Найдена ранее загруженная сборка в кэше: %TEMP%\Civilka-version
    set SCRIPT_DIR=%TEMP%\Civilka-version
    goto :DETECT_MC
)

echo [i] Локальные файлы сборки не найдены рядом со скриптом.
echo [i] Загрузка актуальной сборки с GitHub...
echo.

set WORK_DIR=%TEMP%\Civilka-version
if exist "%WORK_DIR%" rmdir /s /q "%WORK_DIR%" 2>nul
mkdir "%WORK_DIR%" 2>nul

where git >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo [*] Клонирование через Git (--depth 1)...
    git clone --depth 1 https://github.com/civilkaserver-sketch/Civilka-version.git "%WORK_DIR%"
    if exist "%WORK_DIR%\versions\1.21.8-forge-58.1.7" (
        set SCRIPT_DIR=%WORK_DIR%
        goto :DETECT_MC
    )
)

echo [*] Загрузка архива сборки с GitHub через curl...
where curl >nul 2>nul
if %ERRORLEVEL% equ 0 (
    curl -L --progress-bar -o "%TEMP%\civilka_temp.zip" "https://github.com/civilkaserver-sketch/Civilka-version/archive/refs/heads/main.zip"
    if exist "%TEMP%\civilka_temp.zip" (
        echo [*] Распаковка архива...
        powershell -NoProfile -Command "Expand-Archive -Path '%TEMP%\civilka_temp.zip' -DestinationPath '%TEMP%\civilka_extracted' -Force"
        del /f /q "%TEMP%\civilka_temp.zip"
        if exist "%TEMP%\civilka_extracted\Civilka-version-main\versions\1.21.8-forge-58.1.7" (
            set SCRIPT_DIR=%TEMP%\civilka_extracted\Civilka-version-main
            goto :DETECT_MC
        )
    )
)

echo.
echo [ОШИБКА] Не удалось загрузить файлы сборки! Проверьте интернет.
pause
exit /b 1

:DETECT_MC
echo.
echo [*] Поиск папки Minecraft...
set MC_DIR=

:: Проверяем стандартные пути
if exist "%APPDATA%\.minecraft" set MC_DIR=%APPDATA%\.minecraft
if not defined MC_DIR if exist "E:\Games\.minecraft" set MC_DIR=E:\Games\.minecraft
if not defined MC_DIR if exist "D:\Games\.minecraft" set MC_DIR=D:\Games\.minecraft
if not defined MC_DIR if exist "C:\Games\.minecraft" set MC_DIR=C:\Games\.minecraft
if not defined MC_DIR if exist "D:\.minecraft" set MC_DIR=D:\.minecraft
if not defined MC_DIR if exist "E:\.minecraft" set MC_DIR=E:\.minecraft

if defined MC_DIR (
    echo [+] Найдена папка Minecraft: %MC_DIR%
    echo.
    echo Нажмите ENTER для установки в эту папку,
    echo или введите путь вручную:
    set /p USER_MC="Путь (или ENTER): "
    if defined USER_MC set MC_DIR=%USER_MC%
) else (
    echo [!] Папка Minecraft не найдена автоматически.
    echo Пожалуйста, укажите путь к вашей папке .minecraft
    set /p MC_DIR="Путь к .minecraft: "
)

set MC_DIR=%MC_DIR:"=%

if not exist "%MC_DIR%" (
    echo [!] Папка %MC_DIR% не существует. Создать? (Y/N)
    set /p CREATE_ANS="Ваш выбор: "
    if /i "%CREATE_ANS%"=="Y" (
        mkdir "%MC_DIR%" 2>nul
    ) else (
        echo Установка отменена.
        pause
        exit /b 1
    )
)

echo.
echo ======================================================================
echo Начинаем установку файлов в: %MC_DIR%
echo ======================================================================
echo.

:: 1. Копируем версию
echo [1/6] Установка версии Forge 1.21.8...
if not exist "%MC_DIR%\versions\1.21.8-forge-58.1.7" mkdir "%MC_DIR%\versions\1.21.8-forge-58.1.7"
xcopy /E /I /Y /Q "%SCRIPT_DIR%\versions\1.21.8-forge-58.1.7" "%MC_DIR%\versions\1.21.8-forge-58.1.7" >nul

:: 2. Копируем библиотеки
echo [2/6] Копирование библиотек Forge...
if not exist "%MC_DIR%\libraries" mkdir "%MC_DIR%\libraries"
xcopy /E /I /Y /Q "%SCRIPT_DIR%\libraries" "%MC_DIR%\libraries" >nul

:: 3. Копируем моды
echo [3/6] Установка модов (playertrading, OptiFine, Xaeros, etc.)...
if not exist "%MC_DIR%\mods" mkdir "%MC_DIR%\mods"
xcopy /E /I /Y /Q "%SCRIPT_DIR%\mods" "%MC_DIR%\mods" >nul

:: 4. Копируем ресурспаки
echo [4/6] Установка ресурспаков и текстур артефактов...
if not exist "%MC_DIR%\resourcepacks" mkdir "%MC_DIR%\resourcepacks"
xcopy /E /I /Y /Q "%SCRIPT_DIR%\resourcepacks" "%MC_DIR%\resourcepacks" >nul

:: 5. Копируем шейдеры
echo [5/6] Установка шейдерпаков...
if not exist "%MC_DIR%\shaderpacks" mkdir "%MC_DIR%\shaderpacks"
xcopy /E /I /Y /Q "%SCRIPT_DIR%\shaderpacks" "%MC_DIR%\shaderpacks" >nul

:: 6. Конфиги и настройки
echo [6/6] Настройка конфигурации и списка серверов...
if exist "%SCRIPT_DIR%\config" (
    if not exist "%MC_DIR%\config" mkdir "%MC_DIR%\config"
    xcopy /E /I /Y /Q "%SCRIPT_DIR%\config" "%MC_DIR%\config" >nul
)
if exist "%SCRIPT_DIR%\optionsof.txt" copy /Y "%SCRIPT_DIR%\optionsof.txt" "%MC_DIR%\optionsof.txt" >nul
if exist "%SCRIPT_DIR%\optionsshaders.txt" copy /Y "%SCRIPT_DIR%\optionsshaders.txt" "%MC_DIR%\optionsshaders.txt" >nul
if exist "%SCRIPT_DIR%\servers.dat" (
    if not exist "%MC_DIR%\servers.dat" copy /Y "%SCRIPT_DIR%\servers.dat" "%MC_DIR%\servers.dat" >nul
)

:: 7. Регистрация профиля в launcher_profiles.json
powershell -NoProfile -Command "$lp = Join-Path '%MC_DIR%' 'launcher_profiles.json'; if (Test-Path $lp) { try { $json = Get-Content $lp -Raw -Encoding utf8 | ConvertFrom-Json; if (-not $json.profiles) { $json | Add-Member -MemberType NoteProperty -Name 'profiles' -Value ([PSCustomObject]@{}) }; $civ = [PSCustomObject]@{ created = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffZ'); icon = 'Furnace'; lastUsed = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffZ'); lastVersionId = '1.21.8-forge-58.1.7'; name = 'Civilization 1.21.8'; type = 'custom' }; $json.profiles | Add-Member -MemberType NoteProperty -Name 'Civilization' -Value $civ -Force; $json | ConvertTo-Json -Depth 10 | Set-Content $lp -Encoding utf8; Write-Host '[+] Профиль Civilization добавлен в launcher_profiles.json' } catch { } }"

echo.
echo ======================================================================
echo          УСТАНОВКА УСПЕШНО ЗАВЕРШЕНА!
echo ======================================================================
echo.
echo Что делать дальше:
echo 1. Откройте ваш лаунчер (Minecraft Launcher, TLauncher, Legacy Launcher).
echo 2. Выберите версию: 'Civilization 1.21.8' (или '1.21.8-forge-58.1.7').
echo 3. Запустите игру!
echo.
pause
