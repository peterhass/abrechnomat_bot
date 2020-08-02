use Amnesia

defdatabase AbrechnomatBot.Database do
  deftable Payment, [{:id, autoincrement}, :bill_id, :user, :date, :amount, :text], type: :ordered_set, index: [:bill_id] do
    def by_bill(bill_id) do
      case Payment.read_at(bill_id, :bill_id) do
        nil -> []
        payments -> payments
      end
    end
  end

  deftable Bill, [{:id, autoincrement}, :chat_id], type: :ordered_set, index: [:chat_id] do
    def find_or_create_by_chat(chat_id) do
      case find_by_chat(chat_id) do
        nil ->
          %Bill{chat_id: chat_id}
          |> Bill.write()

        bill -> bill
      end
    end

    def find_by_chat(chat_id) do
      case Bill.read_at(chat_id, :chat_id) do
        nil -> nil
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
