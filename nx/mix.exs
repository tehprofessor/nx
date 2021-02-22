defmodule Nx.MixProject do
  use Mix.Project

  @source_url "https://github.com/elixir-nx/nx"
  @version "0.1.0-dev"

  def project do
    [
      app: :nx,
      name: "Nx",
      version: @version,
      elixir: "~> 1.11",
      deps: deps(),
      docs: docs(),
      compilers: [:elixir_make] ++ Mix.compilers()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [{:elixir_make, "~> 0.6"}, {:ex_doc, "~> 0.23", only: :dev}]
  end

  defp docs do
    [
      main: "Nx",
      source_ref: "v#{@version}",
      source_url: @source_url,
      groups_for_modules: [
        # Nx,
        # Nx.Async,
        # Nx.Defn,
        # Nx.Defn.Kernel

        Backends: [
          Nx.BinaryBackend,
          Nx.PytorchBackend,
          Nx.Tensor,
          Nx.Type
        ],
        Compilers: [
          Nx.Defn.Compiler,
          Nx.Defn.Evaluator,
          Nx.Defn.Expr
        ],
        Structs: [
          Nx.Heatmap
        ]
      ]
    ]
  end
end
