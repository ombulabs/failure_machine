defmodule FailureMachine.FailureGroup do
  defstruct [:messages, where: [], number_of_failures: 0]

  def new_failure_group(message, failures) do
    %FailureMachine.FailureGroup{messages: message, number_of_failures: length(failures)}
  end

  def wrap_failures(failures) do
    failures
    |> Enum.map(fn {message, failures} ->
      message
      |> new_failure_group(failures)
      |> reduce_failures(failures)
    end)
  end

  defp reduce_failures(failure_group, failures) do
    Enum.reduce(failures, failure_group, &add_failure_to_group/2)
  end

  defp add_failure_to_group(failure, failure_group) do
    put_in(
      failure_group,
      [Access.key(:where)],
      ["#{failure.file_path}:#{failure.line_number}" | failure_group.where]
    )
  end

  def compare(fg1, fg2) do
    cond do
      fg1.number_of_failures > fg2.number_of_failures -> :gt
      fg1.number_of_failures == fg2.number_of_failures -> :eq
      fg1.number_of_failures < fg2.number_of_failures -> :lt
    end
  end
end
