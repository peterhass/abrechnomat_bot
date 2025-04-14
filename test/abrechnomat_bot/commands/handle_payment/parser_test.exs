defmodule AbrechnomatBot.Commands.HandlePayment.ParserTest do
  use ExUnit.Case
  alias AbrechnomatBot.Commands.HandlePayment.Parser
  alias AbrechnomatBot.I18n

  test "amount and text for another user" do
    i18n = I18n.init(%{currency: "EUR", locale: "de"})

    update = build_update("/add_payment Christina 54,23 Lebensmittel")

    assert Parser.parse({" Christina 54 Lebensmittel", update}, i18n) ==
             {:ok,
              %{
                message_id: 8,
                chat_id: -431_581_683,
                date: ~U[2020-08-11 18:51:34Z],
                amount: %Money{amount: 5423, currency: :EUR},
                own_share: nil,
                text: "Lebensmittel",
                user: %{
                  first_name: "Christina",
                  id: 401_139_989,
                  is_bot: false
                }
              }}
  end

  test "can deal with german number formatting" do
    i18n = I18n.init(%{currency: "EUR", locale: "de"})

    update = build_update("/add_payment Christina 5.423,99 Lebensmittel")

    assert Parser.parse({" Christina 54 Lebensmittel", update}, i18n) ==
             {:ok,
              %{
                message_id: 8,
                chat_id: -431_581_683,
                date: ~U[2020-08-11 18:51:34Z],
                amount: %Money{amount: 542_399, currency: :EUR},
                own_share: nil,
                text: "Lebensmittel",
                user: %{
                  first_name: "Christina",
                  id: 401_139_989,
                  is_bot: false
                }
              }}
  end

  test "can deal with english number formatting" do
    i18n = I18n.init(%{currency: "EUR", locale: "en"})

    update = build_update("/add_payment Christina 5,423.99 Lebensmittel")

    assert Parser.parse({" Christina 54 Lebensmittel", update}, i18n) ==
             {:ok,
              %{
                message_id: 8,
                chat_id: -431_581_683,
                date: ~U[2020-08-11 18:51:34Z],
                amount: %Money{amount: 542_399, currency: :EUR},
                own_share: nil,
                text: "Lebensmittel",
                user: %{
                  first_name: "Christina",
                  id: 401_139_989,
                  is_bot: false
                }
              }}
  end

  describe "get_target_user" do
    test "return text on raw command" do
      assert Parser.get_target_user(
               "/add_payment 12",
               [%{length: 12, offset: 0, type: "bot_command"}]
             ) == [" 12", nil]
    end

    test "return username on mention (and strip @-prefix)" do
      assert Parser.get_target_user(
               "/add_payment @christina 54 Lebensmittel",
               [
                 %{length: 12, offset: 0, type: "bot_command"},
                 %{length: 10, offset: 13, type: "mention"}
               ]
             ) == [
               " 54 Lebensmittel",
               %Telegex.Type.User{username: "christina", id: nil, is_bot: false, first_name: nil}
             ]
    end

    test "return whole user on text mention" do
      user = %{
        first_name: "Christina",
        id: 401_139_989,
        is_bot: false
      }

      assert Parser.get_target_user(
               "/add_payment Christina 54 Lebensmittel",
               [
                 %{length: 12, offset: 0, type: "bot_command"},
                 %{length: 9, offset: 13, type: "text_mention", user: user}
               ]
             ) == [" 54 Lebensmittel", user]
    end
  end

  defp build_update(text) do
    %Telegex.Type.Update{
      callback_query: nil,
      channel_post: nil,
      chosen_inline_result: nil,
      edited_message: nil,
      inline_query: nil,
      message: %Telegex.Type.Message{
        audio: nil,
        caption: nil,
        channel_chat_created: nil,
        chat: %Telegex.Type.Chat{
          first_name: nil,
          id: -431_581_683,
          last_name: nil,
          title: "test123",
          type: "group",
          username: nil
        },
        contact: nil,
        date: 1_597_171_894,
        delete_chat_photo: nil,
        document: nil,
        edit_date: nil,
        entities: [
          %{length: 12, offset: 0, type: "bot_command"},
          %{
            length: 9,
            offset: 13,
            type: "text_mention",
            user: %{
              first_name: "Christina",
              id: 401_139_989,
              is_bot: false
            }
          }
        ],
        from: %Telegex.Type.User{
          first_name: "peterweissnix",
          id: 11_453_244,
          last_name: nil,
          username: "p_ter",
          is_bot: false
        },
        group_chat_created: nil,
        left_chat_member: nil,
        location: nil,
        message_id: 8,
        migrate_from_chat_id: nil,
        migrate_to_chat_id: nil,
        new_chat_photo: [],
        new_chat_title: nil,
        photo: [],
        pinned_message: nil,
        reply_to_message: nil,
        sticker: nil,
        supergroup_chat_created: nil,
        text: text,
        venue: nil,
        video: nil,
        voice: nil
      },
      update_id: 799_027_465
    }
  end
end
