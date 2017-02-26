defmodule Patiently.Mixfile do
  use Mix.Project

  def project do
    [
      app: :patiently,
      version: "0.1.0",
      description: description(),
      package: package(),
      elixir: "~> 1.2",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      dialyzer: [plt_add_deps: :transitive],
      deps: deps()
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp description do
    """
    Helpers for waiting on asynchronous events
    """
  end

  defp package do
    [
      files: ["lib", "LICENSE.txt", "mix.exs", "mix.lock", "README.md"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/dantswain/patiently"},
      maintainers: ["Dan Swain"]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.15", only: :dev},
      {:credo, "~> 0.6.1", only: [:dev, :test]},
      {:dialyxir, "~> 0.5.0", only: :dev, runtime: false}
    ]
  end
end
