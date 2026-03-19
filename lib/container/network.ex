defmodule Container.Network do
  @moduledoc """
  Network management commands.
  """

  alias Container.Command

  def create(name, opts \\ []) do
    Command.dispatch([:network, :create], [name], opts)
  end

  def delete(networks \\ [], opts \\ []) do
    Command.dispatch([:network, :delete], List.wrap(networks), opts)
  end

  def rm(networks \\ [], opts \\ []) do
    delete(networks, opts)
  end

  def prune(opts \\ []) do
    Command.dispatch([:network, :prune], [], opts)
  end

  def list(opts \\ []) do
    Command.dispatch([:network, :list], [], opts, Command.json_output_opts(opts))
  end

  def ls(opts \\ []) do
    list(opts)
  end

  def inspect(networks, opts \\ []) do
    Command.dispatch([:network, :inspect], List.wrap(networks), opts, output: :json)
  end
end
