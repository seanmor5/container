defmodule Container.System.Property do
  @moduledoc """
  System property management commands.
  """

  alias Container.Command

  def list(opts \\ []) do
    Command.dispatch([:system, :property, :list], [], opts, Command.json_output_opts(opts))
  end

  def ls(opts \\ []) do
    list(opts)
  end

  def get(id, opts \\ []) do
    Command.dispatch([:system, :property, :get], [id], opts)
  end

  def set(id, value, opts \\ []) do
    Command.dispatch([:system, :property, :set], [id, value], opts)
  end

  def clear(id, opts \\ []) do
    Command.dispatch([:system, :property, :clear], [id], opts)
  end
end
