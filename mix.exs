defmodule AbsintheUtils.MixProject do
  use Mix.Project

  @version System.get_env("APP_VERSION", "0.0.0-development")
  @source_url "https://github.com/significa/absinthe_utils"
  def project do
    [
      app: :absinthe_utils,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: @source_url,
      package: [
        maintainers: ["Significa"],
        licenses: ["MIT"],
        links: %{"GitHub" => @source_url}
      ],
      docs: [
        source_ref: "v#{@version}",
        extras: [
          "README.md"
        ],
        main: "readme",
        formatters: ["html", "epub"],
        description: "Collection of helpers for absinthe",
        name: "Absinthe Utils"
      ]
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
