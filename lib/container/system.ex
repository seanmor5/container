defmodule Container.System do
  @moduledoc """
  System management commands.

  `Container.System` wraps the `container system` namespace for managing the
  overall container service and inspecting system-level state.
  """

  alias Container.Command

  @doc """
  Starts the container system service.

  `opts` are encoded as CLI flags.

  ## Examples

      Container.System.start()

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container system start`
  as CLI flags.
  """
  def start(opts \\ []) do
    Command.dispatch([:system, :start], [], opts)
  end

  @doc """
  Stops the container system service.

  `opts` are encoded as CLI flags.

  ## Examples

      Container.System.stop()

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container system stop`
  as CLI flags.
  """
  def stop(opts \\ []) do
    Command.dispatch([:system, :stop], [], opts)
  end

  @doc """
  Returns system status information.

  `opts` are encoded as CLI flags. Unless `:quiet` or an explicit non-JSON
  `:format` is provided, this command requests JSON output and returns the
  decoded result.

  ## Examples

      Container.System.status()

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container system status`
  as CLI flags.
  """
  def status(opts \\ []) do
    Command.dispatch([:system, :status], [], opts, Command.json_output_opts(opts))
  end

  @doc """
  Returns version information.

  `opts` are encoded as CLI flags. Unless `:quiet` or an explicit non-JSON
  `:format` is provided, this command requests JSON output and returns the
  decoded result.

  ## Examples

      Container.System.version()

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container system version`
  as CLI flags.
  """
  def version(opts \\ []) do
    Command.dispatch([:system, :version], [], opts, Command.json_output_opts(opts))
  end

  @doc """
  Fetches system logs.

  `opts` are encoded as CLI flags.

  ## Examples

      Container.System.logs()

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container system logs`
  as CLI flags.
  """
  def logs(opts \\ []) do
    Command.dispatch([:system, :logs], [], opts)
  end

  @doc """
  Returns system disk usage information.

  `opts` are encoded as CLI flags. Unless `:quiet` or an explicit non-JSON
  `:format` is provided, this command requests JSON output and returns the
  decoded result.

  ## Examples

      Container.System.df()

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container system df`
  as CLI flags.
  """
  def df(opts \\ []) do
    Command.dispatch([:system, :df], [], opts, Command.json_output_opts(opts))
  end
end
