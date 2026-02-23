# Swarm Skill

`swarm` — это навык для командного параллельного выполнения задач в AI-агентах для кодинга.
Основан на документации Anthropic Agent Teams: https://code.claude.com/docs/en/agent-teams

English version: [README.md](README.md)

## Что делает

- Срабатывает, когда пользователь просит выполнить работу командой или параллельно.
- Делит работу на 4 агента с чёткими зонами ответственности.
- Обеспечивает подход «сначала план», а также изоляцию по файловым областям.
- Требует явного ревью, отслеживания прогресса и корректного завершения.

## Структура репозитория

- `SKILL.md` — полные инструкции и workflow навыка.
- `README.md` — обзор проекта (English).
- `README.ru.md` — обзор проекта (Русский).
- `LICENSE` — лицензия MIT.
- `install.sh` — shell-установщик с интерактивным выбором агентов.
- `scripts/install.js` — установщик на Node.js (для `npx`).
- `package.json` — метаданные npm и точка входа CLI.

## Установка

### Shell (curl)

```sh
curl -fsSL https://raw.githubusercontent.com/teafey/swarm.skill/main/install.sh | bash
```

### NPX (из GitHub)

```sh
npx --yes -p github:teafey/swarm.skill swarm-skill-install
```

Оба установщика автоматически находят директории агентов и показывают интерактивное меню:

```
  Swarm Skill Installer

  SPACE toggle  ↑↓ move  ENTER confirm  q quit

  ❯ [✔] Claude Code  ~/.claude/skills/swarm
    [✔] Codex         ~/.codex/skills/swarm
```

Переключайте цели клавишей **SPACE**, перемещайтесь **стрелками**, нажмите **ENTER** для установки.

### Параметры

| Флаг | Описание |
|------|----------|
| `--yes`, `-y` | Пропустить меню, установить во все найденные агенты |
| `--force`, `-f` | Перезаписать существующие установки |
| `--dir <path>` | Добавить свою директорию skills |
| `-h`, `--help` | Показать справку |

### Переменные окружения (shell-установщик)

| Переменная | Описание |
|------------|----------|
| `CODEX_HOME` | Переопределить домашнюю директорию Codex |
| `REPO_OWNER` | Владелец репозитория на GitHub (по умолчанию: `teafey`) |
| `REPO_NAME` | Название репозитория на GitHub (по умолчанию: `swarm.skill`) |
| `BRANCH` | Ветка Git (по умолчанию: `main`) |

### Примеры

```sh
# Неинтерактивная установка во все найденные агенты
curl -fsSL .../install.sh | bash -s -- --yes

# Перезаписать существующие установки
npx --yes -p github:teafey/swarm.skill swarm-skill-install --force

# Установить в свою директорию
npx --yes -p github:teafey/swarm.skill swarm-skill-install --dir ~/.my-agent/skills
```

### Поддерживаемые агенты

Установщик проверяет наличие следующих директорий:

| Агент | Домашняя директория | Целевая директория |
|-------|--------------------|--------------------|
| Claude Code | `~/.claude` | `~/.claude/skills/swarm` |
| Codex | `~/.codex` (или `$CODEX_HOME`) | `~/.codex/skills/swarm` |

Дополнительные цели можно добавить через `--dir`.

## Использование

Запустите навык в чате, когда нужно параллельное выполнение командой:

```text
/swarm <task>
```

Запуск с указанием модели:

```text
/swarm haiku <task>
/swarm sonnet <task>
/swarm opus <task>
```

Типовые примеры:

```text
/swarm 1. Add auth middleware 2. Add tests 3. Update docs 4. Wire CI
/swarm plan.md
/swarm parallelize checkout flow refactor
```

Поведение:

1. Разбирает ваш запрос на задачи.
2. Делит работу ровно на 4 агентов с изолированной областью работы.
3. Выполняет согласование плана до начала реализации.
4. Отслеживает прогресс и возвращает итоговое резюме.

## Разработка

1. Измените `SKILL.md`.
2. Проверьте поведение на реальных промптах, которые включают swarm-режим.
3. Закоммитьте изменения с понятным scope.

## Публикация

1. `git remote add origin git@github.com:teafey/swarm.skill.git`
2. `git add .`
3. `git commit -m "chore: update installers"`
4. `git push -u origin main`
