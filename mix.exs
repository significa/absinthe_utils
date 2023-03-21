defmodule AbsintheUtils.MixProject do
  use Mix.Project

  @version "0.0.1-development"

  @source_url "https://github.com/significa/absinthe_utils"

  @description "Collection of utils for absinthe"

  def project do
    [
      app: :absinthe_utils,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: @source_url,
      description: @description,
      package: [
        maintainers: ["Significa"],
        licenses: ["MIT"],
        links: %{
          "GitHub" => @source_url,
          "Author Website (Significa)" => "https://significa.co"
        }
      ],
      docs: [
        source_ref: "v#{@version}",
        extras: [
          "README.md"
        ],
        main: "readme",
        formatters: ["html", "epub"],
        description: @description,
        name: "Absinthe Utils",
        groups_for_modules: [
          "Absinthe middlewares": [
            AbsintheUtils.Middleware.ArgLoader,
            AbsintheUtils.Middleware.DeprecatedArgs
          ],
          "Helpers and utility functions": [
            AbsintheUtils.Helpers.Sorting,
            AbsintheUtils.Helpers.Errors
          ]
        ]
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
      {:ecto, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:jason, ">= 1.1.0", only: [:dev, :test], runtime: false}
    ]
  end
end
