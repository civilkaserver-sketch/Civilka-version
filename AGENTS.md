# AGENTS.md — version_repo/ (клиентский модпак)

## Что это

Git-репозиторий клиентской сборки `Civilization`, который качает лаунчер и
игроки. Не «папка с модом», а готовый раздаваемый модпак.

## Что где

- `versions/Civilization/Civilization.json` — профиль TLauncher.
- `versions/Civilization/mods/` — 19 модов, среди них наш
  `playertrading-fabric-1.0.0.jar` (**intermediary**, ~67.5 МБ).
- `versions/Civilization/resourcepacks/CivilizationServerPack.zip` — ресурс-пак.
- `versions/Civilization/config/` — конфиги (Sodium, Iris, Xaero, Voxy,
  `playertrading_events.json`, `playertrading_zones.json`, ...).
- `versions/Civilization/natives/` — нативные библиотеки.
- `install.bat` / `Установка_Civilization.bat` — установщик (PowerShell внутри bat).
- `libraries/` — библиотеки профиля.

## Правила

1. Сюда попадают только **готовые артефакты**. Исходники — в `../mod/`.
2. Наш мод обновляется копированием
   `../mod/playertrading-fabric-1.0.0-intermediary.jar` →
   `versions/Civilization/mods/playertrading-fabric-1.0.0.jar`.
   Хеши должны совпадать.
3. Ресурс-пак здесь может расходиться с `../mod/CivilizationServerPack.zip` и
   `../server/CivilizationServerPack.zip` — синхронизируй явно, если задача
   про пак.
4. `screenshots/`, `shaderpacks/` — пустые (`.gitkeep`), не засоряй.
5. После обновления — коммит и push (репозиторий раздаётся через GitHub).
6. Русский текст — UTF-8 без BOM (важно для `install.bat`, там PowerShell-код).

## Осторожно

- Не удалять и не «оптимизировать» моды: набор подобран под 1.21.8 и
  совместимость проверена вручную.
- Не менять `Civilization.json`/`natives/` без явной задачи.
