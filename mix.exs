defmodule Shaere.MixProject do
  use Mix.Project

  def project do
    [
      app: :shaere,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      # TODO remove inets if we switch to httpoison
      extra_applications: [:inets, :logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # TODO
      {:enacl, github: "syfgkjasdkn/enacl"},
      # TODO remove
      {:erl_base58, "~> 0.0.1"},
      {:ex_rlp, "~> 0.3"},
      {:jason, "~> 1.1"},
      {:dialyxir, "~> 1.0-rc", only: [:dev], runtime: false}
    ]
  end
end
