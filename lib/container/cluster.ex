defmodule Container.Cluster do
  @moduledoc """
  Local Kubernetes cluster commands.

  `Container.Cluster` wraps the experimental `container cluster` namespace.
  The command was renamed from `container k8s` in Apple container 1.6.1.
  It is a CLI plugin, so `container system start` has to be run before these
  functions will work. Subcommands and options can change.
  """

  alias Container.Command

  @doc """
  Creates and starts a local Kubernetes cluster.

  ## Examples

      Container.Cluster.create()
      Container.Cluster.create(name: "my-cluster", cpus: 4, memory: "8g", workers: 3)

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container cluster create`
  as CLI flags.
  """
  def create(opts \\ []) do
    Command.dispatch([:cluster, :create], [], opts)
  end

  @doc """
  Stops and deletes a Kubernetes cluster, including worker nodes.

  Also removes the cluster entry from `~/.kube/config`.

  ## Examples

      Container.Cluster.delete()
      Container.Cluster.delete(name: "my-cluster")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container cluster delete`
  as CLI flags.
  """
  def delete(opts \\ []) do
    Command.dispatch([:cluster, :delete], [], opts)
  end

  @doc """
  Lists Kubernetes clusters.

  The CLI does not document a machine-readable format for this command, so
  the raw command result is returned.

  ## Examples

      Container.Cluster.list()

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container cluster list`
  as CLI flags.
  """
  def list(opts \\ []) do
    Command.dispatch([:cluster, :list], [], opts)
  end

  @doc """
  Writes a cluster's kubeconfig into a kubeconfig file.

  ## Examples

      Container.Cluster.write_config()
      Container.Cluster.write_config(name: "my-cluster", kubeconfig: "~/.kube/my-cluster")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container cluster write-config`
  as CLI flags.
  """
  def write_config(opts \\ []) do
    Command.dispatch([:cluster, :write_config], [], opts)
  end
end
