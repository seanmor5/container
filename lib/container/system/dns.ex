defmodule Container.System.DNS do
  @moduledoc """
  System DNS management commands.

  `Container.System.DNS` wraps the `container system dns` namespace for
  managing DNS entries used by the runtime.
  """

  alias Container.Command

  @doc """
  Creates a DNS entry.

  `domain` is passed as the domain and `opts` are encoded as CLI flags.

  ## Examples

      Container.System.DNS.create("app.local")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container system dns create`
  as CLI flags.
  """
  def create(domain, opts \\ []) do
    Command.dispatch([:system, :dns, :create], [domain], opts)
  end

  @doc """
  Deletes a DNS entry.

  `domain` is passed as the domain and `opts` are encoded as CLI flags.

  ## Examples

      Container.System.DNS.delete("app.local")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container system dns delete`
  as CLI flags.
  """
  def delete(domain, opts \\ []) do
    Command.dispatch([:system, :dns, :delete], [domain], opts)
  end

  @doc """
  Lists DNS entries.

  `opts` are encoded as CLI flags.

  ## Examples

      Container.System.DNS.list()

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container system dns list`
  as CLI flags.
  """
  def list(opts \\ []) do
    Command.dispatch([:system, :dns, :list], [], opts)
  end
end
