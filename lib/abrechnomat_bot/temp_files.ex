defmodule AbrechnomatBot.TempFiles do
  def generate_file_path do
    System.tmp_dir!()
    |> Path.join(random_string())
  end

  defp random_string do
    :rand.uniform(0x100000000)
    |> Integer.to_string(36)
    |> String.downcase
  end
end
