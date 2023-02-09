defmodule FailureMachine do
  @moduledoc """
  Documentation for `FailureMachine`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> FailureMachine.hello()
      :world

  """
  def main(args) do
    {parsed, _, invalid} =
      args
      |> OptionParser.parse(aliases: [h: :help], strict: [info: :string, help: :boolean])

    case invalid do
      [] ->
        process_command(parsed)

      [{"--info", nil}] ->
        IO.puts("The --info option requires a path")

      _ ->
        IO.inspect(invalid)
    end
  end

  def process_command(info: path_string) do
    file_read_results =
      Path.wildcard(path_string)
      |> Enum.map(&File.read/1)
      |> Enum.group_by(fn file_read_result -> elem(file_read_result, 0) end)

    file_read_results[:ok]
    |> Enum.map(fn file_read_result -> elem(file_read_result, 1) end)
    |> Enum.map(fn file_contents -> Poison.decode!(file_contents) end)
    |> Enum.map(fn decoded_data -> extract_failures(decoded_data) end)
    |> List.flatten()
    |> classify()
    |> print()
  end

  def process_command(help: _) do
    IO.puts(IO.ANSI.red() <> "TODO: Add help output" <> IO.ANSI.reset())
  end

  def extract_failures(test_run_data) do
    test_run_data["examples"]
    |> Enum.map(fn elem -> atomize_keys(elem) end)
    |> Enum.filter(fn example -> example[:status] == "failed" end)
    |> Enum.map(fn elem -> struct(Failure, elem) end)
  end

  def atomize_keys(map) do
    map
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    |> Map.new()
  end

  def classify(failures) do
    failures
    |> create_failure_groups()
    |> order_descending()
  end

  def create_failure_groups(failures) do
    failures
    |> Enum.group_by(fn failure -> root_cause(failure) end)
    |> FailureGroup.from_failures_map()
  end

  def root_cause(failure) do
    cond do
      failure.exception == nil ->
        failure.message

      failure.exception != nil ->
        failure.exception["message"]
    end
  end

  def order_descending(failure_groups) do
    failure_groups
    |> Enum.sort({:desc, FailureGroup})
  end

  def print(failure_groups) do
    failure_groups
    |> Enum.each(fn fg -> print_to_console(fg) end)
  end

  def print_to_console(failure_group) do
    IO.puts("""
    #{IO.ANSI.blue()}#{IO.ANSI.bright()}NUMBER OF FAILURES:#{IO.ANSI.reset()} #{failure_group.number_of_failures}\n
    #{IO.ANSI.blue()}#{IO.ANSI.bright()}MESSAGES:#{IO.ANSI.reset()}
    #{IO.ANSI.red()}#{failure_group.messages}#{IO.ANSI.reset()}\n
    #{IO.ANSI.blue()}#{IO.ANSI.bright()}WHERE:#{IO.ANSI.reset()}
    #{format(failure_group.where)}
    #{IO.ANSI.blue()}#{IO.ANSI.bright()}----------------------------------#{IO.ANSI.reset()}
    """)
  end

  def format(file_paths) do
    file_paths
    |> Enum.reduce(List.first(file_paths), fn path, acc -> acc <> "\n#{path}" end)
  end
end
