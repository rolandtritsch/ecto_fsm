defmodule EctoFsm.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_fsm,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: "https://github.com/tableturn/ecto_fsm",
      source_url: "https://github.com/tableturn/ecto_fsm",
      dialyzer: dialyzer(System.get_env("MIX_CACHE_PLT")),
      docs: [],
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
      {:dialyxir, "~> 0.5", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test, runtime: false},
      # All envs
      {:ecto, "~> 3.0"}
    ]
  end

  defp cli_env_for(env, tasks),
    do: Enum.reduce(tasks, [], &Keyword.put(&2, :"#{&1}", env))

  defp dialyzer("true"),
    do: [
      plt_core_path: "/plts",
      plt_file: {:no_warn, "/plts/ttapi_#{Mix.env()}.plt"},
      plt_add_deps: :project
    ]

  defp dialyzer(_), do: [plt_add_deps: :project]
end
