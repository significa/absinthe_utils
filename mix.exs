defmodule AbsintheUtils.MixProject do
  use Mix.Project

  def project do
    [
      app: :absinthe_utils,
      version: System.get_env("APP_VERSION", "0.0.0-development"),
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:absinthe, "~> 1.7"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end
end
