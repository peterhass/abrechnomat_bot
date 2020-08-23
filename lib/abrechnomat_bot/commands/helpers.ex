defmodule AbrechnomatBot.Commands.Helpers do
  alias AbrechnomatBot.Commands.UserCollector

  defmacro defcommand(command_module, text) do
    quote do
      def command(%Nadia.Model.Update{message: %{text: unquote(text) <> text_args}} = update) do
        preprocess_update(update)
        unquote(command_module).command({text_args, update})
      end
    end
  end

  defmacro defcallback(command_module, text) do
    quote do
      def command(%Nadia.Model.Update{callback_query: %{data: unquote(text) <> text_args}} = update) do
        preprocess_update(update)
        unquote(command_module).command_callback({text_args, update})
      end
    end
  end

  def preprocess_update(update) do
    UserCollector.process(update)
  end
end
