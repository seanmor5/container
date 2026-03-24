defmodule Container.Network do
  @moduledoc """
  Network management commands.

  `Container.Network` wraps the `container network` namespace for creating,
  listing, inspecting, and deleting networks.
  """

  alias Container.Command

  @doc """
  Creates a network.

  `name` is passed as the network name and `opts` are encoded as CLI flags.

  ## Examples

      Container.Network.create("app-net")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container network create`
  as CLI flags.
  """
  def create(name, opts \\ []) do
    Command.dispatch([:network, :create], [name], opts)
  end

  @doc """
  Deletes one or more networks.

  `networks` may be a single network name or a list of names, and `opts`
  are encoded as CLI flags.

  ## Examples

      Container.Network.delete("app-net")
      Container.Network.delete(["app-net", "db-net"])

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container network delete`
  as CLI flags.
  """
  def delete(networks \\ [], opts \\ []) do
    Command.dispatch([:network, :delete], List.wrap(networks), opts)
  end

  @doc """
  Removes unused networks.

  `opts` are encoded as CLI flags.

  ## Examples

      Container.Network.prune()

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container network prune`
  as CLI flags.
  """
  def prune(opts \\ []) do
    Command.dispatch([:network, :prune], [], opts)
  end

  @doc """
  Lists networks and returns decoded JSON when supported.

  `opts` are encoded as CLI flags. Unless `:quiet` or an explicit non-JSON
  `:format` is provided, this command requests JSON output and returns the
  decoded result.

  ## Examples

      Container.Network.list()

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container network list`
  as CLI flags.
  """
  def list(opts \\ []) do
    Command.dispatch([:network, :list], [], opts, Command.json_output_opts(opts))
  end

  @doc """
  Inspects one or more networks and decodes the JSON response.

  `networks` may be a single network name or a list of names, and `opts`
  are encoded as CLI flags.

  ## Examples

      Container.Network.inspect("app-net")
      Container.Network.inspect(["app-net", "db-net"])

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container network inspect`
  as CLI flags.
  """
  def inspect(networks, opts \\ []) do
    Command.dispatch([:network, :inspect], List.wrap(networks), opts, output: :json)
  end
end
