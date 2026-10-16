# Чекліст створення n8n-agent-starter

Робочий список, за яким я створюю пакет. Порядок етапів жорсткий: наступний починається, коли закрито **ворота** попереднього. Посилання на вимоги: [TZ.md](../plan/TZ.md), [ROADMAP.md](../plan/ROADMAP.md), [INFRASTRUCTURE.md](INFRASTRUCTURE.md).

Позначки: `[ ]` не зроблено, `[x]` зроблено, 👤 потрібна дія Антона.

---

## Підготовка (планування)
- [x] План інфраструктури
- [x] Архітектурний brief
- [x] ТЗ і роадмап
- [x] INFRASTRUCTURE.md
- [x] 👤 Антон прочитав і погодив INFRASTRUCTURE.md
- [x] 👤 Тунелі: ngrok (основний) + Cloudflare Quick (запасний) + Cloudflare Named (найстабільніший)
- [x] 👤 Створено GitHub-репозиторій `antonhryb21/n8n-agent-starter` і підключено до проєкту
- [x] 👤 `reset.sh` лишаємо

**Ворота:** усі 👤 пункти вище закриті (крім репозиторію: етапи 0–3 можна робити локально).

---

## Етап 0. Каркас репозиторію
- [x] Гілка `setup/skeleton`
- [x] Структура папок: `docs/`, `scripts/`, `tests/`, `workflows/`, `.github/workflows/`
- [x] `.gitignore` (`.env`, `*.env.local`, `n8n_data/`, `*.log`, `.DS_Store`)
- [x] `.env.example` з усіма змінними з INFRASTRUCTURE.md §7, без значень
- [x] `.gitattributes` (LF для `*.sh` і `*.command`)
- [x] `LICENSE` (MIT)
- [x] `README.md`-заглушка з посиланням на INFRASTRUCTURE.md
- [x] Перенести INFRASTRUCTURE.md у репозиторій
- [x] Перевірка: `git status` після створення `.env` не показує його

**Ворота:** перший коміт запушено, draft PR відкрито. (Коміт є локально, push після створення репозиторію.)

---

## Етап 1. Перевірка ризиків (до коду)
- [x] **R1** ngrok free: Traffic Policy доступна (до 5 правил) → deny усього, крім `/webhook/*` і `/healthz`. Cloudflare Named: правила шляхів у панелі. Cloudflare Quick: обмежити не можна, задокументовано
- [x] **R2** Як Telegram Trigger у зафіксованій версії n8n реєструє webhook з `WEBHOOK_URL`; різниця test/production URL → висновок у ТЗ
- [x] **R3** Вимоги Docker Desktop до Mac, сумісність з OrbStack → у docs/01-setup
- [x] **R4** Як Gatekeeper поводиться з `.command` з ZIP і з git clone → у docs/03-troubleshooting
- [x] **R5** ngrok free: 20 000 запитів і 1 ГБ на місяць, 1 dev domain `*.ngrok-free.app`, сторінка-попередження лише для браузерів. Поточні ліміти ngrok free і сторінка-попередження → у INFRASTRUCTURE.md §9
- [x] Версії: `n8nio/n8n:2.43.7` (stable), `ngrok/ngrok:3.39.11-alpine`, `cloudflare/cloudflared:2026.10.1`
- [x] Оновити INFRASTRUCTURE.md, якщо висновки щось змінили

**Ворота:** кожен ризик має висновок і обхідний шлях.

---

## Етап 2. Документація (описує поведінку до коду)
- [x] `README.md`: що це, 5 кроків запуску, посилання на docs
- [x] `docs/01-setup.md`: Docker Desktop, BotFather, ngrok, Setup.command
- [x] `docs/02-first-workflow.md`: імпорт echo-workflow, credential, Active, перевірка
- [x] `docs/03-troubleshooting.md`: щонайменше 5 типових проблем з рішенням
- [x] `docs/04-security.md`: правила секретів, заміна токенів, пароль власника
- [x] Місця для скріншотів позначено `<!-- screenshot: ... -->`
- [x] `docs/05-cloudflare.md`: обидва режими Cloudflare
- [x] Вичитати мову: просто, без жаргону, один крок = одна дія
- [x] 👤 Антон погодив документацію (2026-10-16)

**Ворота:** документацію погоджено.

---

## Етап 3. Тести (пишуться до коду, спершу червоні)
- [x] `tests/lib.sh`: спільні функції виводу ✅/❌ з підказкою
- [x] `tests/smoke.sh`:
  - [x] T1 Docker і контейнери running
  - [x] T2 `localhost:5678/healthz` = 200
  - [x] T3 `https://$NGROK_DOMAIN/healthz` = 200
  - [x] T4 Telegram `getMe` успішний
  - [x] T5 `getWebhookInfo.url` = домен, `last_error_message` порожній
  - [x] T6 `/` і `/rest` через тунель недоступні (якщо R1 = так)
- [x] `tests/secrets-check.sh`:
  - [x] S1 `.env` не відстежується git
  - [x] S2 немає шаблонів токенів Telegram/ngrok у відстежуваних файлах і в `workflows/*.json`
- [x] `.github/workflows/ci.yml`: Q1 shellcheck, Q2 `docker compose config`, S1, S2, gitleaks, T2
- [x] Pre-commit хук `.githooks/pre-commit` (gitleaks, якщо встановлений, + secrets-check) (опційно для студента, описаний у docs/04)
- [x] Перевірка: тести запускаються і падають зрозуміло, бо коду ще немає
- [x] Перевірка: S2 ловить підкладений фейковий токен

**Ворота:** тести виконуються, CI запускається, падіння очікувані.

---

## Етап 4. Розробка
- [x] `docker-compose.yml`: n8n (порт `127.0.0.1:5678`, volume, змінні) + ngrok (статичний домен, inspector `127.0.0.1:4040`, правило шляхів з R1)
- [x] Профілі compose `cloudflare-quick` і `cloudflare-named` (вибір через `COMPOSE_PROFILES`)
- [x] `scripts/setup.sh` (F1): створює `.env`, питає 3 значення, генерує ключ, не перезаписує без підтвердження
- [x] `scripts/start.sh` (F2): перевіряє Docker і `.env`, `compose up`, чекає healthz до 60 с, відкриває браузер, друкує адресу
- [x] `scripts/stop.sh` (F3)
- [x] `scripts/check.sh` (F4): запускає smoke + secrets-check
- [x] `scripts/reset.sh` з подвійним підтвердженням (якщо погоджено)
- [x] `Setup.command`, `Start.command`, `Stop.command`, `Check.command` (F6)
- [x] `workflows/telegram-echo.json` (F5) без credentials
- [ ] Сумісність з bash 3.2 і zsh (N4): код без bash 4+ можливостей, shellcheck чистий; перевірити на Mac на етапі 5
- [ ] Повторний `start` нічого не ламає (N5): перевірити на Mac на етапі 5 (локально Docker Hub обмежив завантаження образів)
- [x] Повідомлення скриптів українською

**Ворота:** усі CI-перевірки зелені, локальний прогін T2 і S1–S2 зелений.

---

## Етап 5. Перевірка на Mac
- [ ] 👤 Антон проходить README на своєму Mac з нуля
- [ ] 👤 `Check.command`: T1–T6 зелені
- [ ] 👤 E2E: повідомлення боту → відповідь
- [ ] 👤 Перезапуск Mac → `Start` → бот відповідає без нових налаштувань
- [ ] 👤 Режими `cloudflare-quick` і (за наявності домену) `cloudflare-named` запускаються
- [ ] Виправити все знайдене, повторити перевірку
- [ ] Звірити з DoD у ТЗ §7

**Ворота:** DoD виконано.

---

## Етап 6. Реліз
- [ ] `CHANGELOG.md`
- [ ] PR переведено з draft у ready, CI зелений
- [ ] 👤 Антон змерджив PR
- [ ] Тег `v0.1.0`
- [ ] 👤 Репозиторій позначено як Template
- [ ] Оновити роадмап і пам'ять проєкту

---

## Правила, яких я тримаюсь на кожному етапі
- Жодних справжніх токенів у файлах, комітах, повідомленнях і логах.
- Кожна зміна поведінки спершу відображається в документації.
- Кожна нова функція має тест або пункт ручної перевірки.
- Зміни вимог записуються в ТЗ до того, як змінюється код.
- Нічого не мерджу сам, мердж робить Антон.
