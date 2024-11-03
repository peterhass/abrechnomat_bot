# AbrechnomatBot

Telegram bot for bill splitting. Supports an unlimited amount of debtors/creditors on a bill. 
Calculates as little transactions as possible to pay everybody out.

## Usage

- Add it to a group (works best if you give it admin privileges)
- Send `/add_payment` see on it should be used
- `/revert_payment` to remove an added payment
- Use `/bill_stats` to see the current amount and needed transactions
- `/close_bill` after all payments are done (new bill starts immediately after that)

## Development Setup

- Create bot in BotFather to get the bot api token
- `cp .env.example .env.local`
- Fill in fields in `.env.local`
- Set up env variables for current session: `source .env.local`
- Run: `iex -S mix`

## Deployment

- `git clone https://github.com/peterhass/abrechnomat_bot.git repo`
- `make build && make service`
- Setup database if needed: `DB_CREATE=true ~/.local/share/abrechnomat_bot/bin/abrechnomat_bot start_iex`
- `systemctl --user start abrechnomat_bot.service`

## TODO 

- Nadia is dead. Migrate to https://github.com/visciang/telegram ?
- Use webhooks instead of polling
- Respect edited messages?
