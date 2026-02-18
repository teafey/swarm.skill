# Swarm Skill

`swarm` — это навык Codex/Claude для командного параллельного выполнения задач.
Он основан на документации Anthropic Agent Teams: https://code.claude.com/docs/en/agent-teams

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
- `install.sh` — shell-установщик одной командой.
- `scripts/install.js` — установщик на Node.js (для `npx`).
- `package.json` — метаданные npm и точка входа CLI.

## Быстрая установка

Установка через shell:

```sh
curl -fsSL https://raw.githubusercontent.com/teafey/swarm.skill/main/install.sh | sh
```

Установка через NPX (из GitHub):

```sh
npx --yes -p github:teafey/swarm.skill swarm-skill-install
```

По умолчанию файлы навыка устанавливаются в `${CODEX_HOME:-$HOME/.codex}/skills/swarm`.

## Локальное использование

Поместите эту папку в директорию со skills и убедитесь, что рантайм агента может загрузить `SKILL.md`.

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
3. `git commit -m "chore: bootstrap swarm skill repo"`
4. `git push -u origin main`
