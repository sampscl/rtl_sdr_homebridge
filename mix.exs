defmodule RtlSdrHomebridge.MixProject do
  use Mix.Project

  @doc """
  Get the version of the app. This will do sorta-smart things when git is not
  present on the build machine (it's possible, especially in Docker containers!)
  by using the "version" environment variable.

  ## Returns
  - version `String.t`
  """
  def version do
    "git describe"
    |> System.shell(cd: Path.dirname(__ENV__.file))
    |> then(fn
      {version, 0} -> Regex.replace(~r/^[[:alpha:]]*/, String.trim(version), "")
      {_barf, _exit_code} -> System.get_env("version", "0.0.0-UNKNOWN")
    end)
    |> tap(&IO.puts("Version: #{&1}"))
  end

  def project do
    [
      app: :rtl_sdr_homebridge,
      version: version(),
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      # this makes dialyzer include mix behaviors in the PLT so that
      # dialyxir doesn't complain about our mix tasks and unknown
      # mix module behaviors, thanks Stack Overflow: https://stackoverflow.com/questions/51208388/how-to-fix-dialyzer-callback-info-about-the-behaviour-is-not-available
      dialyzer: [plt_add_apps: [:mix]],
      name: "RTL-SDR  Homebridge",
      docs: [
        main: "RtlSdrHomebridge",
        extras: [
          "README.md"
        ]
      ],
      releases: [
        rtl_sdr_homebridge: [
          include_executables_for: [:unix],
          applications: [runtime_tools: :permanent]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {RtlSdrHomebridge, []}
    ]
  end

  def aliases do
    [
      espec: &espec/1
    ]
  end

  def espec(args) do
    Mix.Task.run("espec", args ++ ["--no-start"])
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:espec, "~> 1.8", only: :test},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:qol_up, "~> 1.1"}
    ]
  end
end
