defmodule AbrechnomatBot.TempFiles do
  def get_temp_file(suffix) do
    System.tmp_dir!()
    |> Path.join("#{random_string()}-#{suffix}")
  end

  defp random_string do
    :rand.uniform(0x100000000)
    |> Integer.to_string(36)
    |> String.downcase
  end
end
