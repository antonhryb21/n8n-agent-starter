# n8n-agent-starter

Готове середовище для курсу про AI-агентів: твій Telegram-бот надсилає повідомлення в **n8n** на твоєму Mac, а n8n відповідає.

```
Telegram  →  тунель (HTTPS)  →  n8n на твоєму Mac  →  відповідь у Telegram
```

## Що потрібно

- Mac з macOS 13 або новішою (Intel чи Apple Silicon), 8 ГБ пам'яті або більше.
- Акаунт Telegram.
- Безкоштовний акаунт [ngrok](https://ngrok.com).
- Близько 20 хвилин на перший запуск.

## Запуск за 5 кроків

1. **Встанови Docker Desktop** і запусти його. → [docs/01-setup.md](docs/01-setup.md#1-docker-desktop)
2. **Створи бота** в @BotFather і скопіюй токен. → [docs/01-setup.md](docs/01-setup.md#2-telegram-бот)
3. **Візьми ключ і адресу ngrok.** → [docs/01-setup.md](docs/01-setup.md#3-ngrok)
4. **Зніми блокування macOS** з папки пакета (одна команда) → [docs/01-setup.md](docs/01-setup.md#4-завантаж-пакет), потім **двічі клацни `Setup.command`** і встав три значення.
5. **Двічі клацни `Start.command`**, потім підключи перший workflow. → [docs/02-first-workflow.md](docs/02-first-workflow.md)

Напиши боту "привіт". Якщо він відповів, усе працює 🎉

## Щоденне використання

| Дія | Що клацнути |
|---|---|
| Запустити | `Start.command` |
| Зупинити | `Stop.command` |
| Перевірити, що все працює | `Check.command` |

## Якщо щось не так

1. Двічі клацни `Check.command`: він покаже, що саме зламалось, і що робити.
2. Подивись [docs/03-troubleshooting.md](docs/03-troubleshooting.md).

## Документація

- [INFRASTRUCTURE.md](INFRASTRUCTURE.md): як влаштована система.
- [docs/01-setup.md](docs/01-setup.md): встановлення.
- [docs/02-first-workflow.md](docs/02-first-workflow.md): перший workflow.
- [docs/03-troubleshooting.md](docs/03-troubleshooting.md): типові проблеми.
- [docs/04-security.md](docs/04-security.md): секрети й безпека.
- [docs/05-cloudflare.md](docs/05-cloudflare.md): альтернативні тунелі Cloudflare.

## Безпека в одному реченні

Твої токени живуть лише у файлі `.env` на твоєму Mac і ніколи не потрапляють у git. Деталі: [docs/04-security.md](docs/04-security.md).
