defmodule FailureMachine.Classifier do
  def classify(examples) do
    classified_failures =
      examples.failures
      |> Enum.group_by(fn failure -> failure[:message] end)
      |> order_descending()
      |> Keyword.values()
      |> Enum.map(fn failures ->
        Enum.reduce(failures, %{messages: [], files: []}, fn failure, acc ->
          messages = [failure[:message] | acc[:messages]]

          files =
            if List.last(acc[:files]) != failure[:file] do
              [failure[:file] | acc[:files]]
            else
              acc[:files]
            end

          %{
            messages: messages,
            files: files
          }
        end)
      end)

    %FailureMachine.Examples{
      failures: classified_failures,
      summary: examples.summary
    }
  end

  def classify_by_file(examples) do
    classified_failures =
      examples.failures
      |> Enum.group_by(fn failure ->
        failure[:file]
        |> String.split(":", trim: true)
        |> List.first()
      end)
      |> order_descending()
      |> Keyword.values()
      |> Enum.map(fn failures ->
        Enum.reduce(failures, %{messages: [], files: []}, fn failure, acc ->
          messages = [failure[:message] | acc[:messages]]

          files =
            if List.last(acc[:files]) != failure[:file] do
              [failure[:file] | acc[:files]]
            else
              acc[:files]
            end

          %{
            messages: messages,
            files: files
          }
        end)
      end)

    %FailureMachine.Examples{
      failures: classified_failures,
      summary: examples.summary
    }
  end

  def order_descending(failure_groups) do
    failure_groups
    |> Enum.sort(fn examples1, examples2 ->
      length(elem(examples1, 1)) >= length(elem(examples2, 1))
    end)
  end
end
