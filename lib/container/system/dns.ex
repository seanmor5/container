defmodule Container.System.DNS do
  @moduledoc """
  System DNS management commands.
  """

  alias Container.Command

  def create(domain, opts \\ []) do
    Command.dispatch([:system, :dns, :create], [domain], opts)
  end

  def delete(domain, opts \\ []) do
    Command.dispatch([:system, :dns, :delete], [domain], opts)
  end

  def rm(domain, opts \\ []) do
    delete(domain, opts)
  end

  def list(opts \\ []) do
    Command.dispatch([:system, :dns, :list], [], opts)
  end

  def ls(opts \\ []) do
    list(opts)
  end
end
