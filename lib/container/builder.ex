defmodule Container.Builder do
  @moduledoc """
  Builder service management commands.

  `Container.Builder` wraps the `container builder` namespace, which
  manages the builder service used for image builds.
  """

  alias Container.Command

  @doc """
  Starts the builder service.

  `opts` are encoded as CLI flags.

  ## Examples

      Container.Builder.start()

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container builder start`
  as CLI flags.
  """
  def start(opts \\ []) do
    Command.dispatch([:builder, :start], [], opts)
  end

  @doc """
  Returns builder status information.

  `opts` are encoded as CLI flags. Unless `:quiet` or an explicit non-JSON
  `:format` is provided, this command requests JSON output and returns the
  decoded result.

  ## Examples

      Container.Builder.status()

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container builder status`
  as CLI flags.
  """
  def status(opts \\ []) do
    Command.dispatch([:builder, :status], [], opts, Command.json_output_opts(opts))
  end

  @doc """
  Stops the builder service.

  `opts` are encoded as CLI flags.

  ## Examples

      Container.Builder.stop()

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container builder stop`
  as CLI flags.
  """
  def stop(opts \\ []) do
    Command.dispatch([:builder, :stop], [], opts)
  end

  @doc """
  Deletes the builder service.

  `opts` are encoded as CLI flags.

  ## Examples

      Container.Builder.delete()

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container builder delete`
  as CLI flags.
  """
  def delete(opts \\ []) do
    Command.dispatch([:builder, :delete], [], opts)
  end
end
