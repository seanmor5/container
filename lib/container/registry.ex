defmodule Container.Registry do
  @moduledoc """
  Registry management commands.

  `Container.Registry` wraps the `container registry` namespace for logging
  into registries, logging out, and listing configured registries.
  """

  alias Container.Command

  @doc """
  Logs into a registry.

  `server` is passed as the registry server. If `:password_stdin` is set to a
  binary, the value is sent over stdin and `--password-stdin` is added to the
  CLI arguments. Other options are encoded as CLI flags.

  ## Examples

      Container.Registry.login("ghcr.io", username: "sean", password_stdin: "secret")

  ## Options

    * `:password_stdin` - send the registry password over stdin

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container registry login`
  as CLI flags.
  """
  def login(server, opts \\ []) do
    {password_stdin, opts} = Keyword.pop(opts, :password_stdin)

    op_opts =
      []
      |> Command.put_stdin(normalize_password(password_stdin))

    cli_opts =
      case password_stdin do
        nil -> opts
        true -> Keyword.put(opts, :password_stdin, true)
        _binary -> Keyword.put(opts, :password_stdin, true)
      end

    Command.dispatch([:registry, :login], [server], cli_opts, op_opts)
  end

  @doc """
  Logs out of a registry.

  `server` is passed as the registry server and `opts` are encoded as CLI
  flags.

  ## Examples

      Container.Registry.logout("ghcr.io")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container registry logout`
  as CLI flags.
  """
  def logout(server, opts \\ []) do
    Command.dispatch([:registry, :logout], [server], opts)
  end

  @doc """
  Lists configured registries and returns decoded JSON when supported.

  `opts` are encoded as CLI flags. Unless `:quiet` or an explicit non-JSON
  `:format` is provided, this command requests JSON output and returns the
  decoded result.

  ## Examples

      Container.Registry.list()

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container registry list`
  as CLI flags.
  """
  def list(opts \\ []) do
    Command.dispatch([:registry, :list], [], opts, Command.json_output_opts(opts))
  end

  defp normalize_password(true), do: nil
  defp normalize_password(nil), do: nil
  defp normalize_password(password), do: to_string(password)
end
