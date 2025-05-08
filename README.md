
![ChatGPT Image May 8, 2025, 08_08_57 PM (1)](https://github.com/user-attachments/assets/e9c569a8-5bf5-4ed5-b2c6-aa174076a92d)

# AbrechnomatBot

A Telegram bot for bill splitting. Supports an unlimited number of debtors/creditors on a bill and calculates the minimum number of transactions necessary to settle everyone's accounts. The bot supports various currencies and locales, allowing users to manage expenses in their preferred settings. Bill exports are designed for easy import into spreadsheet applications like Google Sheets.

## Usage

- Add the bot to a group (works best with admin privileges)
- `/pay`: Initiates the wizard for adding payments
- `/add_payment`: Adds a payment for you or another user
- `/revert_payment`: Removes a previously added payment
- `/bill_stats`: Displays the current totals and required transactions
- `/close_bill`: Closes the current bill when all payments are completed (a new bill will start automatically after this). A CSV export of payments will be generated after the bill is closed.
- `/set_locale`: Sets internationalization settings, including locale, currency, and time zone
- `/export_payments`: Generates a CSV export of payments. The values are formatted for easy import into spreadsheets (e.g., Google Sheets) based on localization settings.

## Development Setup

1. Create the bot through [BotFather](https://telegram.me/BotFather) to obtain the bot API token
1. Run `cp .env.example .env.local`
1. Complete the fields in `.env.local`
1. Set up environment variables for the current session using `source .env.local`
1. Execute `iex -S mix`

## Deployment

1. Clone the repository: `git clone https://github.com/peterhass/abrechnomat_bot.git repo`
1. Build and set up the service: `make build && make service`
1. Update the configuration at: `~/.config/abrechnomat_bot`
1. Initialize the database if needed: `DB_CREATE=true ~/.local/share/abrechnomat_bot/bin/abrechnomat_bot start_iex`
1. Start the service: `systemctl --user start abrechnomat_bot.service`

### Updating

1. Backup the database `Mnesia.<username>@<hostname>`
1. Pull the latest changes: `git pull`
1. Build and re-install the service: `make build && make service`
1. Restart the service `systemctl --user restart abrechnomat_bot.service`
1. Check logs: `journalctl --user -u abrechnomat_bot.service -r`

## Ideas / future improvements

- Generate pre-filled PayPal links for final payments (requires users to configure their PayPal account)
- Implement a tipping mechanism for the bot provider (possibly post-bill completion)
- Handle edge cases: Users joining or leaving the group while a bill is open
