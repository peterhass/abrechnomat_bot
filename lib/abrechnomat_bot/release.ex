defmodule AbrechnomatBot.Release do
  @app :abrechnomat_bot

  def migrate do
    load_app()

    AbrechnomatBot.Tasks.DbCreate.run()
    # TODO: create new db if not there
    # TODO
    #
  end

  defp load_app do
    Application.load(@app)
  end
end
