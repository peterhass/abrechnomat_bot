defmodule AbrechnomatBot.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec


    children = [
      worker(AbrechnomatBot.CommandReceiver, [])
    ]


    opts = [strategy: :one_for_one, name: AbrechnomatBot.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
