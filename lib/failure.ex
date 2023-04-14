defmodule Failure do
  defstruct [:description, :file_path, :line_number, :full_description, :id, :status, :exception]

  def new_failure(%{"status" => "failed"} = example) do
    struct(Failure, atomize_keys(elem))
  end

  defp atomize_keys(map) do
    Enum.into(map, %{}, fn {k, v} -> {String.to_atom(k), v} end)
  end
end
