defmodule ReqGa.MixProject do
  use Mix.Project

  def project do
    [
      app: :req_ga,
      name: "ReqGA",
      description: "A plugin for Req for interacting with Google Analytics 4 APIs.",
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: [
        main: "readme",
        source_url: "https://github.com/haubie/req_ga",
        homepage_url: "https://github.com/haubie/req_ga",
        logo: "logo-hexdoc.png",
        assets: "assets",
        extras: [
          "README.md",
          "livebook/req_ga_demo.livemd",
          {:"LICENSE", [title: "License (MIT)"]},
        ]
      ]
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
      {:req, "~> 0.4.5"},
      {:goth, "~> 1.3.0"},
      {:table, "~> 0.1.1", optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package() do
    [
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "LICENSE",
      ],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/haubie/req_ga",
        },
      maintainers: ["David Haubenschild"]
    ]
  end
end
