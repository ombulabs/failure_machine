defmodule FailureMachine do
  @moduledoc """
  Documentation for `FailureMachine`.
  """
  import SweetXml

  alias FailureMachine.Classifier

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
    |> take(limit)
    |> print()
  end

  def process_command(info: path_string, by_file: _by_file) do
    path_string
    |> get_failures()
    |> Classifier.classify_by_file()
    |> print()
  end

  def process_command(info: path_string, by_file: _by_file, limit: limit) do
    path_string
    |> get_failures()
    |> Classifier.classify_by_file()
    |> take(limit)
    |> print()
  end

  def take(examples, limit) do
    failures =
      examples.failures
      |> Enum.take(limit)

    %FailureMachine.Examples{
      failures: failures,
      summary: examples.summary
    }
  end

  def get_failures(file_path) do
    file_path
    |> Path.wildcard()
    |> Enum.map(&File.read/1)
    |> Enum.reduce([], fn
      {:ok, content}, acc -> [process_file_contents(content) | acc]
      _, acc -> acc
    end)
    |> Enum.reject(fn examples -> examples.failures == [] end)
    |> Enum.reduce(fn examples, acc -> FailureMachine.merge_examples(acc, examples) end)
  end

  def process_file_contents(contents) do
    contents
    |> decode()
  end

  def merge_examples(examples, other_examples) do
    %FailureMachine.Examples{
      failures: examples.failures ++ other_examples.failures,
      summary: %{
        examples: examples.summary[:examples] + other_examples.summary[:examples],
        failures: examples.summary[:failures] + other_examples.summary[:failures],
        pending: examples.summary[:pending] + other_examples.summary[:pending]
      }
    }
  end

  def decode(content) do
    <<first_char, _::binary>> = content

    case first_char do
      ?{ ->
        parse_json(content)

      ?< ->
        parse_junit(content)
    end
  end

  def parse_json(content) do
    decoded_content = Poison.decode!(content)

    failures =
      decoded_content["examples"]
      |> Enum.filter(fn example -> Map.has_key?(example, "exception") end)
      |> Enum.map(fn failure -> Map.take(failure, ["exception", "file_path", "line_number"]) end)
      |> Enum.map(fn failure ->
        %{
          message: failure["exception"]["message"],
          file: "#{failure["file_path"]}:#{failure["line_number"]}"
        }
      end)

    %FailureMachine.Examples{
      failures: failures,
      summary: %{
        examples: decoded_content["summary"]["example_count"],
        failures: decoded_content["summary"]["failure_count"],
        pending: decoded_content["summary"]["pending_count"]
      }
    }
  end

  def parse_junit(content) do
    decoded_content = decode_xml(content)

    failures =
      Enum.map(decoded_content[:failures], fn failure ->
        %{
          message: List.to_string(failure[:message]),
          file: List.to_string(failure[:file])
        }
      end)

    summary =
      Enum.map(decoded_content[:summary], fn {key, value} -> {key, List.to_integer(value)} end)
      |> Map.new()

    failure_examples = Map.merge(decoded_content, %{failures: failures, summary: summary})

    %FailureMachine.Examples{
      failures: failure_examples[:failures],
      summary: failure_examples[:summary]
    }
  end

  def decode_xml(content) do
    content
    |> xpath(
      ~x"/testsuite"e,
      failures: [~x"./testcase[failure]"l, file: ~x"./@file", message: ~x"./failure/text()"],
      summary: [
        ~x"/testsuite"e,
        examples: ~x"./@tests",
        failures: ~x"./@failures",
        pending: ~x"./@skipped"
      ]
    )
  end

  def print(examples) do
    examples.failures
    |> Enum.each(fn failures -> print_to_console(failures) end)

    print_summary(examples.summary)
  end

  def print_to_console(failures) do
    IO.puts("""
    #{IO.ANSI.blue()}#{IO.ANSI.bright()}NUMBER OF FAILURES:#{IO.ANSI.reset()} #{length(failures[:messages])}\n
    #{IO.ANSI.blue()}#{IO.ANSI.bright()}MESSAGES:#{IO.ANSI.reset()}
    #{IO.ANSI.red()}#{format(failures[:messages])}#{IO.ANSI.reset()}\n
    #{IO.ANSI.blue()}#{IO.ANSI.bright()}WHERE:#{IO.ANSI.reset()}
    #{format(failures[:files])}
    #{IO.ANSI.blue()}#{IO.ANSI.bright()}----------------------------------#{IO.ANSI.reset()}
    """)
  end

  def print_summary(summary) do
    IO.puts("""
      #{IO.ANSI.yellow()}#{IO.ANSI.bright()}SUMMARY:#{IO.ANSI.reset()}\n\n
      #{IO.ANSI.blue()}#{IO.ANSI.bright()}EXAMPLES:#{IO.ANSI.reset()} #{summary[:examples]}\n
      #{IO.ANSI.blue()}#{IO.ANSI.bright()}FAILURES:#{IO.ANSI.reset()} #{summary[:failures]}\n
      #{IO.ANSI.blue()}#{IO.ANSI.bright()}PENDING:#{IO.ANSI.reset()} #{summary[:pending]}\n
    """)
  end

  def format(strings) do
    Enum.join(strings, "\n")
  end
end
