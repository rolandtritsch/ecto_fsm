defmodule EctoFsm.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_fsm,
      version: "0.2.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: "https://github.com/tableturn/ecto_fsm",
      source_url: "https://github.com/tableturn/ecto_fsm",
      dialyzer: dialyzer(System.get_env("MIX_CACHE_PLT")),
      docs: docs(),
      description: description(),
      package: package(),
      consolidate_protocols: Mix.env() != :test,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: cli_env_for(:test, ~w(
            coveralls coveralls.detail coveralls.html coveralls.json coveralls.post
          ))
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
      # Dev / test deps
      {:credo, "~> 0.10", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test, runtime: false},
      # All envs
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0"},
      {:ecto_enum, "~> 1.2"}
    ]
  end

  defp cli_env_for(env, tasks),
    do: Enum.reduce(tasks, [], &Keyword.put(&2, :"#{&1}", env))

  defp dialyzer("true"),
    do:
      dialyzer_common() ++
        [
          plt_core_path: "/plts",
          plt_file: {:no_warn, "/plts/ttapi_#{Mix.env()}.plt"}
        ]

  defp dialyzer(_), do: dialyzer_common()

  defp dialyzer_common,
    do: [
      plt_add_deps: :project,
      ignore_warnings: ".dialyzer-ignore.exs"
    ]

  defp docs,
    do: [
      main: "Ecto.FSM",
      source_url: "https://github.com/tableturn/ecto_fsm",
      source_ref: "master"
    ]

  defp description,
    do: """
    Provides DSL and functions for defining and handling `Ecto.Schema`
    based FSM
    """

  defp package,
    do: [
      maintainers: ["Jean Parpaillon"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/tableturn/ecto_fsm",
        "Doc" => "http://hexdocs.pm/ecto_fsm"
      }
    ]
end
