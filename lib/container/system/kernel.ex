defmodule Container.System.Kernel do
  @moduledoc """
  System kernel management commands.
  """

  alias Container.Command

  def set(opts \\ []) do
    Command.dispatch([:system, :kernel, :set], [], opts)
  end
end
