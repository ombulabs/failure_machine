defmodule FailureMachine.FailureGroup do
  defstruct messages: [], where: [], number_of_failures: 0

  def new_failure_group(message, failures) do
    %FailureMachine.FailureGroup{messages: [message], number_of_failures: length(failures)}
  end

  def new_failure_group(_file, failures, _by_file) do
    %FailureMachine.FailureGroup{number_of_failures: length(failures)}
  end

  def wrap_failures(failures) do
    failures
    |> Enum.map(fn {message, failures} ->
      message
      |> new_failure_group(failures)
      |> add_failure_locations(failures)
      |> add_failure_messages(failures)
    end)
  end

  def wrap_failures(failures, by_file) do
    failures
    |> Enum.map(fn {file, failures} ->
      file
      |> new_failure_group(failures, by_file)
      |> add_failure_locations(failures)
    end)
  end

  defp add_failure_locations(failure_group, failures) do
    Enum.reduce(failures, failure_group, fn failure, failure_group ->
      put_in(failure_group, [Access.key(:where)], [
        "#{failure.file_path}:#{failure.line_number}" | failure_group.where
      ])
    end)
  end

  defp add_failure_messages(failure_group, failures) do
    Enum.reduce(failures, failure_group, fn failure, failure_group ->
      put_in(failure_group, [Access.key(:messages)], [
        "#{failure.exception["message"]}" | failure_group.messages
      ])
    end)
  end

  def compare(fg1, fg2) do
    cond do
      fg1.number_of_failures > fg2.number_of_failures -> :gt
      fg1.number_of_failures == fg2.number_of_failures -> :eq
      fg1.number_of_failures < fg2.number_of_failures -> :lt
    end
  end
end
