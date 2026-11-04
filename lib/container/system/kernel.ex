defmodule Container.System.Kernel do
  @moduledoc """
  System kernel management commands.

  `Container.System.Kernel` wraps the `container system kernel` namespace
  for applying kernel-related settings.
  """

  alias Container.Command

  @doc """
  Installs or updates the Linux kernel used by the runtime.

  `opts` are encoded as CLI flags.

  ## Examples

      Container.System.Kernel.set(recommended: true)
      Container.System.Kernel.set(binary: "/path/to/vmlinux", arch: "arm64")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container system kernel set`
  as CLI flags.
  """
  def set(opts \\ []) do
    Command.dispatch([:system, :kernel, :set], [], opts)
  end
end
