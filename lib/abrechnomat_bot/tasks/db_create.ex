defmodule AbrechnomatBot.Tasks.DbCreate do
  def run() do
    Amnesia.Schema.create
    db = AbrechnomatBot.Database

    Amnesia.start
    try do
      db.create!([disk: [node()]])
      :ok = db.wait(150000)
    after
      Amnesia.stop
    end
  end
end
