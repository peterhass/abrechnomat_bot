use Amnesia

defdatabase AbrechnomatBot.Database do
  deftable(
    Payment,
    [{:id, autoincrement}, :bill_id, :user, :date, :amount, :text],
    type: :ordered_set,
    index: [:bill_id]
  )

  deftable Bill, [{:id, autoincrement}, :chat_id], type: :ordered_set, index: [:chat_id] do
    def find_or_create(chat_id) do
      case Bill.read_at(chat_id, :chat_id) do
        nil ->
          %Bill{chat_id: chat_id}
          |> Bill.write()

        bills -> Enum.at(bills, 0)
      end
    end

    def add_payment(self, user, date, amount, text) do
      payment = %Payment{bill_id: self.id, user: user, date: date, amount: amount, text: text}
      IO.puts("[DB] add_payment #{inspect(payment, pretty: true)}") # TODO: remove
      payment |> Payment.write()
    end
  end
end
