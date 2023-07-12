defmodule FailureMachine.Failure do
  defstruct [:description, :file_path, :line_number, :full_description, :id, :status, :exception]

  def new_failure(%{"status" => "failed"} = elem) do
    struct(FailureMachine.Failure, atomize_keys(elem))
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
      |> Enum.find(message(failure), fn message ->
        message(failure) == message
      end)

    Map.update(map, failure_message, [failure], fn failure_list -> failure_list ++ [failure] end)
  end
end
