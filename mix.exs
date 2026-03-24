defmodule Container.MixProject do
  use Mix.Project

  @source_url "https://github.com/seanmor5/container"
  @version "0.1.0"

  def project do
    [
      app: :container,
      version: @version,
      name: "Container",
      elixir: "~> 1.19",
      cli: cli(),
      docs: docs(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Elixir library for Apple Containers",
      package: package()
    ]
  end

  def cli do
    [
      preferred_envs: [
        docs: :docs,
        "hex.publish": :docs
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
      {:ex_doc, "~> 0.40", only: :docs}
    ]
  end

  defp package do
    [
      maintainers: ["Sean Moriarity"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "Container",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
