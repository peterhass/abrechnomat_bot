defmodule AbrechnomatBot.Commands.HandlePayment do
  require Amnesia
  require Amnesia.Helper
  alias AbrechnomatBot.Database.{Chat, Bill, Payment, User}
  alias AbrechnomatBot.I18n
  alias __MODULE__.Parser
  import Phoenix.HTML

  def command(
        {
          _,
          %Telegex.Type.Update{
            message: %{
              chat: %{id: chat_id}
            }
          }
        } = args
      ) do
    i18n = chat_i18n(chat_id, new_transaction: true)

    args
    |> Parser.parse(i18n)
    |> inject_user
    |> execute
  end

  def inject_user({:ok, %{user: user} = options}) do
    Amnesia.transaction do
      case full_user_resolve(user) do
        nil -> {:error, "Unable to find user", options}
        full_user -> {:ok, put_in(options, [:user], full_user)}
      end
    end
  end

  def inject_user(arg) do
    arg
  end

  def execute({:error, _reason, %{chat_id: chat_id, message_id: message_id}}) do
    usage()
    |> reply(chat_id, message_id)
  end

  def execute(
        {:ok,
         %{
           chat_id: chat_id,
           message_id: message_id,
           user: user,
           date: date,
           amount: amount,
           own_share: own_share,
           text: text
         }}
      ) do
    Amnesia.transaction do
      i18n = chat_i18n(chat_id)

      Bill.find_or_create_by_chat(chat_id)
      |> Bill.add_payment(full_user_resolve(user), date, amount, own_share, text)
      |> payment_message(i18n)
      |> reply(chat_id, message_id)
    end
  end

  def usage do
    cmd_usage = "/add_payment [@<username>] <amount> [(<own_share>%] [EUR] [text]"

    examples =
      [
        {"You paid 10 EUR for the group", "/add_payment 10 Pizza"},
        {"Another person paid 10 EUR for the group", "/add_payment @anotherPerson 10 Seafood"},
        {"You paid something you didn't partake in",
         "/add_payment 10 (0%) Eating pizza without me"}
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

  defp full_user_resolve(%{username: username}) when not is_nil(username) do
    User.find_by_username(username)
  end

  defp full_user_resolve(%{id: id}) do
    User.find(id)
  end

  defp reply(text, chat_id, message_id) do
    Telegex.send_message(chat_id, text, reply_to_message_id: message_id, parse_mode: "HTML")
  end

  def payment_message(
        %Payment{id: id, user: user, date: date, amount: amount, text: text} = payment,
        i18n
      ) do
    [
      "Added following payment ...",
      "ID: #{id}",
      Abrechnomat.Users.to_short_string(user),
      "#{I18n.datetime!(date, i18n)}",
      "#{I18n.money!(amount, i18n)}",
      payment_message_share(payment, i18n),
      "Text: #{text}"
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
    |> html_escape
    |> safe_to_string
  end

  defp payment_message_share(%Payment{amount: _, own_share: own_share}, _i18n)
       when is_nil(own_share) do
    nil
  end

  defp payment_message_share(%Payment{amount: amount, own_share: own_share}, i18n) do
    localized_share_amount =
      Money.multiply(amount, own_share)
      |> I18n.money!(i18n)

    "own share: #{own_share}% = #{localized_share_amount}"
  end

  defp chat_i18n(chat_id, new_transaction: true) do
    Amnesia.transaction do
      chat_i18n(chat_id)
    end
  end

  defp chat_i18n(chat_id) do
    chat_id
    |> Chat.find_or_default()
    |> Chat.i18n()
  end
end
