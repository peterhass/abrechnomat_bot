defmodule AbrechnomatBot.Commands.HandlePayment do
  require Amnesia
  require Amnesia.Helper
  alias AbrechnomatBot.Database.{Bill, Payment}
  alias __MODULE__.Parser

  def command(args) do
    args
    |> Parser.parse
    |> execute
  end

  def execute(%{chat_id: chat_id, user: user, from_username: from_username, date: date, amount: amount, text: text}) do
    Amnesia.transaction do
      Bill.find_or_create_by_chat(chat_id)
      |> Bill.add_payment(user || from_username, date, amount, text)
    end
  end
end
