defmodule FailureMachine do
  @moduledoc """
  Documentation for `FailureMachine`.
  """

  alias FailureMachine.Classifier
  alias FailureMachine.Failure

  @doc """
  Hello world.

  ## Examples

      iex> FailureMachine.hello()
      :world

  """
  def main(args) do
    args
    |> parse_options()
    |> case do
      {parsed, _, []} -> process_command(parsed)
      {_, _, [{"--info", nil}]} -> IO.puts("The --info option requires a path")
      {_, _, [{"--limit", nil}]} -> IO.puts("The --limit option requires a value")
      {_, _, invalid} -> IO.inspect(invalid)
    end
  end

  defp parse_options(args) do
    OptionParser.parse(
      args,
      aliases: [h: :help],
      strict: [
        info: :string,
        help: :boolean,
        limit: :integer,
        by_file: :boolean
      ]
    )
  end

  def process_command(help: _) do
    IO.puts(IO.ANSI.red() <> "TODO: Add help output" <> IO.ANSI.reset())
  end

  def process_command(info: path_string) do
    path_string
    |> get_failures()
    |> Classifier.classify()
    |> print()
  end

  def process_command(info: path_string, limit: limit) do
    path_string
    |> get_failures()
    |> Classifier.classify()
    |> Enum.take(limit)
    |> print()
  end

  def process_command(info: path_string, by_file: by_file) do
    path_string
    |> get_failures()
    |> Classifier.classify(by_file)
    |> print()
  end

  def process_command(info: path_string, by_file: by_file, limit: limit) do
    path_string
    |> get_failures()
    |> Classifier.classify(by_file)
    |> Enum.take(limit)
    |> print()
  end

  def get_failures(file_path) do
    file_path
    |> Path.wildcard()
    |> Enum.map(&File.read/1)
    |> Enum.reduce([], fn
      ({:ok, contents}, acc) -> [process_file_contents(contents)|acc]
      (_, acc) -> acc
    end)
    |> List.flatten()
  end

  defp process_file_contents(contents) do
    contents
    |> Poison.decode!()
    |> extract_failures()
  end
  
  defp extract_failures(%{"examples" => examples} = _all_file_content) do
    examples
    |> Enum.reduce([], fn
      (%{"status" => "failed"} = example, acc) -> [Failure.new_failure(example)|acc]
      (_, acc) -> acc
    end)
  end

  def print(failure_groups) do
    failure_groups
    |> Enum.each(fn fg -> print_to_console(fg) end)
  end

  def print_to_console(failure_group) do
    IO.puts("""
    #{IO.ANSI.blue()}#{IO.ANSI.bright()}NUMBER OF FAILURES:#{IO.ANSI.reset()} #{failure_group.number_of_failures}\n
    #{IO.ANSI.blue()}#{IO.ANSI.bright()}MESSAGES:#{IO.ANSI.reset()}
    #{IO.ANSI.red()}#{format(failure_group.messages)}#{IO.ANSI.reset()}\n
    #{IO.ANSI.blue()}#{IO.ANSI.bright()}WHERE:#{IO.ANSI.reset()}
    #{format(failure_group.where)}
    #{IO.ANSI.blue()}#{IO.ANSI.bright()}----------------------------------#{IO.ANSI.reset()}
    """)
  end

  def format(file_paths) do
    Enum.join(file_paths, "\n")
  end
end
