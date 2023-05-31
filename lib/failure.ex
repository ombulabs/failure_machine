defmodule Failure do
  defstruct [:description, :file_path, :line_number, :full_description, :id, :status, :exception]

  def new_failure(%{"status" => "failed"} = elem) do
    struct(Failure, atomize_keys(elem))
  end

  defp atomize_keys(map) do
    Enum.into(map, %{}, fn {k, v} -> {String.to_atom(k), v} end)
  end

  def message(failure) do
    failure.exception["message"]
  end

  def sort_into(map, failure) do
    failure_message =
      Map.keys(map)
      |> Enum.find(Failure.message(failure), fn message ->
        String.jaro_distance(message, Failure.message(failure)) > 0.8
      end)

    Map.update(map, failure_message, [failure], fn failure_list -> failure_list ++ [failure] end)
  end
end
