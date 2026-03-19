defmodule Container.Builder do
  @moduledoc """
  Builder management commands.
  """

  alias Container.Command

  def start(opts \\ []) do
    Command.dispatch([:builder, :start], [], opts)
  end

  def status(opts \\ []) do
    Command.dispatch([:builder, :status], [], opts, Command.json_output_opts(opts))
  end

  def stop(opts \\ []) do
    Command.dispatch([:builder, :stop], [], opts)
  end

  def delete(opts \\ []) do
    Command.dispatch([:builder, :delete], [], opts)
  end

  def rm(opts \\ []) do
    delete(opts)
  end
end
