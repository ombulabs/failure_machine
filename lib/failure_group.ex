defmodule FailureGroup do
  defstruct [:messages, where: [], number_of_failures: 0]

  def from_failure_lists(failure_lists) do
    failure_lists
    |> Enum.map(fn failures -> from_failures(failures) end)
  end

  def from_failures(failures) do
    first_failure = List.first(failures)
    failure_group = %FailureGroup{messages: first_failure.exception["message"]}

    failures
    |> Enum.reduce(failure_group, fn failure, failure_group ->
      add_failure(failure, failure_group)
    end)
  end

  def add_failure(failure, failure_group) do
    %{failure_group | number_of_failures: failure_group.number_of_failures + 1}
    |> Map.merge(%{where: failure_group.where ++ ["#{failure.file_path}:#{failure.line_number}"]})
  end

  def compare(fg1, fg2) do
    cond do
      fg1.number_of_failures > fg2.number_of_failures -> :gt
      fg1.number_of_failures == fg2.number_of_failures -> :eq
      fg1.number_of_failures < fg2.number_of_failures -> :lt
    end
  end
end
