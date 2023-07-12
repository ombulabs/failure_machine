defmodule FailureMachine.MixProject do
  use Mix.Project

  def project do
    [
      app: :failure_machine,
      version: "0.2.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: FailureMachine]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 5.0.0"},
      {:ex_doc, "~> 0.29.1", only: :dev, runtime: false}
    ]
  end
end
