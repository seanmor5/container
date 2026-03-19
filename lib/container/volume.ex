defmodule Container.Volume do
  @moduledoc """
  Volume management commands.
  """

  alias Container.Command

  def create(name, opts \\ []) do
    Command.dispatch([:volume, :create], [name], opts)
  end

  def delete(volumes \\ [], opts \\ []) do
    Command.dispatch([:volume, :delete], List.wrap(volumes), opts)
  end

  def rm(volumes \\ [], opts \\ []) do
    delete(volumes, opts)
  end

  def prune(opts \\ []) do
    Command.dispatch([:volume, :prune], [], opts)
  end

  def list(opts \\ []) do
    Command.dispatch([:volume, :list], [], opts, Command.json_output_opts(opts))
  end

  def ls(opts \\ []) do
    list(opts)
  end

  def inspect(volumes, opts \\ []) do
    Command.dispatch([:volume, :inspect], List.wrap(volumes), opts, output: :json)
  end
end
