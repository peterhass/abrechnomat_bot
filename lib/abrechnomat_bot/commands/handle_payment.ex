defmodule AbrechnomatBot.Commands.HandlePayment do
  require Amnesia
  require Amnesia.Helper
  alias AbrechnomatBot.Database.{Bill, Payment}
  alias __MODULE__.Parser
  import Phoenix.HTML

  def command(args) do
    args
    |> Parser.parse()
    |> execute
  end

  def execute({:error, reason, %{chat_id: chat_id, message_id: message_id}}) do
    usage
    |> reply(chat_id, message_id)
  end

  def execute({:ok, %{
        chat_id: chat_id,
        message_id: message_id,
        user: user,
        from_username: from_username,
        date: date,
        amount: amount,
        own_share: own_share,
        text: text
      }}) do
    Amnesia.transaction do
      Bill.find_or_create_by_chat(chat_id)
      |> Bill.add_payment(user || from_username, date, amount, own_share, text)
      |> payment_message
      |> reply(chat_id, message_id)
    end
  end

  def usage do
    cmd_usage = "/add_payment [@<username>] <amount> [(<own_share>%] [EUR] [text]"
    examples = [
      {"You paid 10 EUR for the group", "/add_payment 10 Pizza"},
      {"Another person paid 10 EUR for the group", "/add_payment @anotherPerson 10 Drugs"},
      {"You paid something you didn't partake in", "/add_payment 10 (0%) Eating pizza without me"}
    ]
    |> Enum.map(fn {desc, cmd} -> ~E"<%= desc %>: <code><%= cmd %></code>" end)

    ~E"""
    <code><%= cmd_usage %></code>
    <strong>Examples</strong>
    <%= Enum.at(examples, 0) %>
    <%= Enum.at(examples, 1) %>
    <%= Enum.at(examples, 2) %>
    """
    |> safe_to_string
  end

  defp reply(text, chat_id, message_id) do
    Nadia.send_message(chat_id, text, reply_to_message_id: message_id, parse_mode: "HTML")
  end

  def payment_message(%Payment{id: id, user: user, date: date, amount: amount, text: text} = payment) do
    [
      "Added following payment ...",
      "ID: #{id}",
      "@#{user}",
      "#{date}",
      "#{amount}",
      payment_message_share(payment),
      "Text: #{text}"
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
    |> html_escape
    |> safe_to_string
  end

  defp payment_message_share(%Payment{amount: _, own_share: own_share}) when is_nil(own_share) do
    nil
  end

  defp payment_message_share(%Payment{amount: amount, own_share: own_share}) do
    "own share: #{own_share}% = #{Money.multiply(amount, own_share)}"
  end
end
