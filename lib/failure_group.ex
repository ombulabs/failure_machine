defmodule FailureGroup do
  defstruct [:messages, where: [], number_of_failures: 0]

  def from_failures_map(failures_map) do
    failures_map
    |> Enum.map(fn {message, failures} -> from_failures(message, failures) end)
  end

  def from_failures(message, failures) do
    failure_group = %FailureGroup{messages: message, number_of_failures: length(failures)}

    failures
    |> Enum.reduce(failure_group, fn failure, failure_group ->
      add_failure(failure, failure_group)
    end)
  end

  def add_failure(failure, failure_group) do
    Map.merge(failure_group, %{
      where: failure_group.where ++ ["#{failure.file_path}:#{failure.line_number}"]
    })
  end

  def compare(fg1, fg2) do
    cond do
      fg1.number_of_failures > fg2.number_of_failures -> :gt
      fg1.number_of_failures == fg2.number_of_failures -> :eq
      fg1.number_of_failures < fg2.number_of_failures -> :lt
    end
  end
end
