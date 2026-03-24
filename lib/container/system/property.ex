defmodule Container.System.Property do
  @moduledoc """
  System property management commands.

  `Container.System.Property` wraps the `container system property`
  namespace for listing, reading, setting, and clearing system properties.
  """

  alias Container.Command

  @doc """
  Lists system properties and returns decoded JSON when supported.

  `opts` are encoded as CLI flags. Unless `:quiet` or an explicit non-JSON
  `:format` is provided, this command requests JSON output and returns the
  decoded result.

  ## Examples

      Container.System.Property.list()

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to
  `container system property list` as CLI flags.
  """
  def list(opts \\ []) do
    Command.dispatch([:system, :property, :list], [], opts, Command.json_output_opts(opts))
  end

  @doc """
  Gets a system property.

  `id` is passed as the property identifier and `opts` are encoded as CLI
  flags.

  ## Examples

      Container.System.Property.get("dns.domain")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to
  `container system property get` as CLI flags.
  """
  def get(id, opts \\ []) do
    Command.dispatch([:system, :property, :get], [id], opts)
  end

  @doc """
  Sets a system property.

  `id` is the property identifier, `value` is the new value, and `opts` are
  encoded as CLI flags.

  ## Examples

      Container.System.Property.set("dns.domain", "app.local")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to
  `container system property set` as CLI flags.
  """
  def set(id, value, opts \\ []) do
    Command.dispatch([:system, :property, :set], [id, value], opts)
  end

  @doc """
  Clears a system property.

  `id` is passed as the property identifier and `opts` are encoded as CLI
  flags.

  ## Examples

      Container.System.Property.clear("dns.domain")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to
  `container system property clear` as CLI flags.
  """
  def clear(id, opts \\ []) do
    Command.dispatch([:system, :property, :clear], [id], opts)
  end
end
