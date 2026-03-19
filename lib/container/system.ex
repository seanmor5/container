defmodule Container.System do
  @moduledoc """
  System management commands.
  """

  alias Container.Command

  def start(opts \\ []) do
    Command.dispatch([:system, :start], [], opts)
  end

  def stop(opts \\ []) do
    Command.dispatch([:system, :stop], [], opts)
  end

  def status(opts \\ []) do
    Command.dispatch([:system, :status], [], opts, Command.json_output_opts(opts))
  end

  def version(opts \\ []) do
    Command.dispatch([:system, :version], [], opts, Command.json_output_opts(opts))
  end

  def logs(opts \\ []) do
    Command.dispatch([:system, :logs], [], opts)
  end

  def df(opts \\ []) do
    Command.dispatch([:system, :df], [], opts, Command.json_output_opts(opts))
  end
end
