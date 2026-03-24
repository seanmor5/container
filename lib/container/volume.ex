defmodule Container.Volume do
  @moduledoc """
  Volume management commands.

  `Container.Volume` wraps the `container volume` namespace for creating,
  listing, inspecting, and deleting volumes.
  """

  alias Container.Command

  @doc """
  Creates a volume.

  `name` is passed as the volume name and `opts` are encoded as CLI flags.

  ## Examples

      Container.Volume.create("app-data")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container volume create`
  as CLI flags.
  """
  def create(name, opts \\ []) do
    Command.dispatch([:volume, :create], [name], opts)
  end

  @doc """
  Deletes one or more volumes.

  `volumes` may be a single volume name or a list of names, and `opts` are
  encoded as CLI flags.

  ## Examples

      Container.Volume.delete("app-data")
      Container.Volume.delete(["app-data", "cache"])

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container volume delete`
  as CLI flags.
  """
  def delete(volumes \\ [], opts \\ []) do
    Command.dispatch([:volume, :delete], List.wrap(volumes), opts)
  end

  @doc """
  Removes unused volumes.

  `opts` are encoded as CLI flags.

  ## Examples

      Container.Volume.prune()

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container volume prune`
  as CLI flags.
  """
  def prune(opts \\ []) do
    Command.dispatch([:volume, :prune], [], opts)
  end

  @doc """
  Lists volumes and returns decoded JSON when supported.

  `opts` are encoded as CLI flags. Unless `:quiet` or an explicit non-JSON
  `:format` is provided, this command requests JSON output and returns the
  decoded result.

  ## Examples

      Container.Volume.list()

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container volume list`
  as CLI flags.
  """
  def list(opts \\ []) do
    Command.dispatch([:volume, :list], [], opts, Command.json_output_opts(opts))
  end

  @doc """
  Inspects one or more volumes and decodes the JSON response.

  `volumes` may be a single volume name or a list of names, and `opts` are
  encoded as CLI flags.

  ## Examples

      Container.Volume.inspect("app-data")
      Container.Volume.inspect(["app-data", "cache"])

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container volume inspect`
  as CLI flags.
  """
  def inspect(volumes, opts \\ []) do
    Command.dispatch([:volume, :inspect], List.wrap(volumes), opts, output: :json)
  end
end
