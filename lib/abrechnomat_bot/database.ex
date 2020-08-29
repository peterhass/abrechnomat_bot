use Amnesia

defdatabase AbrechnomatBot.Database do
  deftable Migration, [:id, :date], type: :ordered_set do
    def get_current_version do
      case Migration.first() do
        nil -> nil
        %Migration{id: id} -> id
      end
    end

    def set_version(version) do
      %Migration{id: version, date: NaiveDateTime.utc_now()}
      |> Migration.write()
    end
  end

  deftable Payment, [{:id, autoincrement}, :bill_id, :user, :date, :amount, :own_share, :text],
    type: :ordered_set,
    index: [:bill_id] do
    def by_bill(bill_id) do
      case Payment.read_at(bill_id, :bill_id) do
        nil -> []
        payments -> payments
      end
    end

    def delete_by(bill_id: bill_id, payment_id: payment_id) do
      case Payment.read(payment_id) do
        nil ->
          {:error, :not_found}

        payment ->
          case payment do
            %{bill_id: ^bill_id} -> Payment.delete(payment_id)
            _ -> {:error, :wrong_bill}
          end
      end
    end
  end

  deftable Bill, [{:id, autoincrement}, :chat_id], type: :ordered_set, index: [:chat_id] do
    def find_or_create_by_chat(chat_id) do
      case find_by_chat(chat_id) do
        nil ->
          %Bill{chat_id: chat_id}
          |> Bill.write()

        bill ->
          bill
      end
    end

    def delete_with_payments(bill_id) do
      # TODO: error handling
      Payment.by_bill(bill_id)
      |> Enum.each(fn %{id: id} -> Payment.delete(id) end)

      Bill.delete(bill_id)
    end

    def find_by_chat(chat_id) do
      case Bill.read_at(chat_id, :chat_id) do
        nil -> nil
        bills -> Enum.at(bills, 0)
      end
    end

    def add_payment(self, user, date, amount, own_share, text) do
      payment = %Payment{
        bill_id: self.id,
        user: user,
        date: date,
        amount: amount,
        own_share: own_share,
        text: text
      }

      # TODO: remove
      IO.puts("[DB] add_payment #{inspect(payment, pretty: true)}")
      payment |> Payment.write()
    end
  end

  deftable User, [:id, :username, :first_name, :last_name], type: :ordered_set, index: [:username] do
    @type t :: %User{
            id: Integer.t(),
            username: String.t(),
            first_name: String.t(),
            last_name: String.t()
          }

    def find(id) do
      User.read(id)
    end

    def find_by_username(username) do
      case User.read_at(username, :username) do
        nil -> nil
        users -> Enum.at(users, 0)
      end
    end
  end
end
