defmodule FailureMachine.Classifier do
	alias FailureMachine.Failure
	alias FailureMachine.FailureGroup

  def classify(failures) do
    failures
    |> Enum.reduce(%{}, fn failure, acc -> Failure.sort_into(acc, failure) end)
    |> FailureGroup.wrap_failures()
    |> Enum.sort({:desc, FailureGroup})
    |> order_descending()
  end

  def classify(failures, by_file) do
    failures
    |> Enum.reduce(%{}, fn failure, acc -> Map.update(acc, failure.file_path, [failure], fn failure_list -> failure_list ++ [failure] end) end)
    |> FailureGroup.wrap_failures(by_file)
    |> Enum.sort({:desc, FailureGroup})
    |> order_descending()
  end

  def order_descending(failure_groups) do
    failure_groups
    |> Enum.sort({:desc, FailureGroup})
  end
end