defmodule Container do
  @moduledoc """
  Elixir library for Apple's `container` CLI.

  ## Overview

  The public API mirrors the CLI shape as closely as possible. This module
  covers the top-level container lifecycle and inspection commands:

    * `run/3` - create and start a container from an image
    * `build/2` - build an image from a local build context
    * `create/3` - create a container from an image without starting it
    * `start/2` - start a stopped container
    * `stop/2` - stop one or more containers
    * `kill/2` - send a signal to one or more running containers
    * `delete/2` - delete one or more containers
    * `list/1` - list containers
    * `logs/2` - fetch logs for a container
    * `inspect/2` - inspect one or more containers
    * `stats/2` - retrieve container statistics
    * `exec/3` - execute a process inside a running container
    * `export/2` - export a stopped container's filesystem
    * `prune/1` - remove stopped containers

  CLI flags are passed through from function keyword options. For example, `detach: true`
  becomes `--detach`.

  Subcommands are grouped into submodules by CLI namespace:

    * `Container.Image` manages image listing, inspection, transfer, tagging, and cleanup.
    * `Container.Network` manages named container networks.
    * `Container.Volume` manages persistent volumes.
    * `Container.Registry` manages registry login, logout, and configured registries.
    * `Container.Builder` manages the builder service used for image builds.
    * `Container.System` manages engine-wide lifecycle, status, logs, version, and disk usage.
    * `Container.System.DNS` manages system DNS entries for the container runtime.
    * `Container.System.Property` manages system property listing and mutation.
    * `Container.System.Kernel` applies kernel-related system settings.

  ### Examples

      Container.run("nginx:latest", [], name: "web", detach: true)
      Container.list(all: true)
      Container.inspect("web")
      Container.logs("web", tail: 50)

  ## Streaming Execution

  `exec/3` supports both collected output and streaming sessions. Use the
  default collect mode when you want a single result:

      Container.exec("web", ["sh", "-lc", "echo hello"])

  Pass `stream: true` when you need to keep the process open and interact
  with it incrementally through `Container.Exec`:

      {:ok, session} =
        Container.exec("web", ["sh"], stream: true, interactive: true)

      :ok = Container.Exec.write(session, "echo hello\\n")
      {:ok, chunk} = Container.Exec.read(session, 5_000)

  ## Configurable Transports

  Each function builds a configuration-only `Container.Operation`, and then dispatches
  execution through a configured `Container.Transport`. The default transport implementation
  uses a port to interact with the external `container` executable. If for some reason you
  need a new/different transport, you can implement the transport behaviour and configure
  `Container` to use your implementation.
  """

  alias Container.Command

  @type command_args :: [String.t() | atom() | integer()]
  @type identifiers :: String.t() | atom() | integer() | [String.t() | atom() | integer()]
  @type option :: {atom(), term()}
  @type options :: [option()]

  @doc """
  Runs a container from an image.

  `image` is the image reference to run, `command` is appended after the
  image name, and `opts` are encoded as CLI flags.

  ## Examples

      Container.run("nginx:latest")

      # Specify a command
      Container.run("alpine:latest", ["echo", "hello"])

      # Specify options
      Container.run("nginx:latest", [], name: "web", detach: true)

  ## Options
    
    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container run` as a CLI flags.
  """
  @spec run(String.t(), command_args(), options()) ::
          {:ok, term()} | {:error, Container.Error.t()}
  def run(image, command \\ [], opts \\ []) do
    Command.dispatch([:run], [image | List.wrap(command)], opts)
  end

  @doc """
  Builds an image from a local build context.

  `context` is passed as the build context path and `opts` are encoded as
  CLI flags.

  ## Examples

      Container.build()

      # Specify a build context
      Container.build("./app")

      # Specify a tag
      Container.build(".", tag: "app:latest")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container build` as CLI flags.
  """
  @spec build(String.t(), options()) :: {:ok, term()} | {:error, Container.Error.t()}
  def build(context \\ ".", opts \\ []) do
    Command.dispatch([:build], [context], opts)
  end

  @doc """
  Creates a container from an image without starting it.

  `image` is the image reference to create from, `command` is appended after
  the image name, and `opts` are encoded as CLI flags.

  ## Examples

      Container.create("nginx:latest")

      # Specify a command
      Container.create("alpine:latest", ["sleep", "60"], name: "job")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container create` as CLI flags.
  """
  @spec create(String.t(), command_args(), options()) ::
          {:ok, term()} | {:error, Container.Error.t()}
  def create(image, command \\ [], opts \\ []) do
    Command.dispatch([:create], [image | List.wrap(command)], opts)
  end

  @doc """
  Starts a stopped container.

  `container` is passed as the container identifier and `opts` are encoded as
  CLI flags.

  ## Examples

      Container.start("web")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container start` as CLI flags.
  """
  @spec start(String.t() | atom() | integer(), options()) ::
          {:ok, term()} | {:error, Container.Error.t()}
  def start(container, opts \\ []) do
    Command.dispatch([:start], [container], opts)
  end

  @doc """
  Stops one or more containers.

  `containers` may be a single container identifier or a list of identifiers,
  and `opts` are encoded as CLI flags.

  ## Examples

      Container.stop("web")
      Container.stop(["web", "worker"])

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container stop` as CLI flags.
  """
  @spec stop(identifiers(), options()) :: {:ok, term()} | {:error, Container.Error.t()}
  def stop(containers \\ [], opts \\ []) do
    Command.dispatch([:stop], List.wrap(containers), opts)
  end

  @doc """
  Sends a signal to one or more running containers.

  `containers` may be a single container identifier or a list of identifiers,
  and `opts` are encoded as CLI flags.

  ## Examples

      Container.kill("web")
      Container.kill(["web", "worker"], signal: "TERM")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container kill` as CLI flags.
  """
  @spec kill(identifiers(), options()) :: {:ok, term()} | {:error, Container.Error.t()}
  def kill(containers \\ [], opts \\ []) do
    Command.dispatch([:kill], List.wrap(containers), opts)
  end

  @doc """
  Deletes one or more containers.

  `containers` may be a single container identifier or a list of identifiers,
  and `opts` are encoded as CLI flags.

  ## Examples

      Container.delete("web")
      Container.delete(["web", "worker"])

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container delete` as CLI flags.
  """
  @spec delete(identifiers(), options()) :: {:ok, term()} | {:error, Container.Error.t()}
  def delete(containers \\ [], opts \\ []) do
    Command.dispatch([:delete], List.wrap(containers), opts)
  end

  @doc """
  Lists containers and returns decoded JSON when supported.

  `opts` are encoded as CLI flags. Unless `:quiet` or an explicit non-JSON
  `:format` is provided, this command requests JSON output and returns the
  decoded result.

  ## Examples

      Container.list()
      Container.list(all: true)

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container list` as CLI flags.
  """
  @spec list(options()) :: {:ok, term()} | {:error, Container.Error.t()}
  def list(opts \\ []) do
    Command.dispatch([:list], [], opts, Command.json_output_opts(opts))
  end

  @doc """
  Executes a process inside a running container.

  `container` is the target container identifier, `command` is the process
  and arguments to run, and `opts` are encoded as CLI flags.

  ## Examples

      Container.exec("web", ["sh", "-lc", "echo hello"])
      Container.exec("web", ["cat"], stdin: "hello\\n")

  ## Options

    * `:stdin` - send one-shot stdin to the command in collect mode

    * `:stream` - return a `Container.Exec` session instead of collecting output

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container exec` as CLI flags.
  """
  @spec exec(String.t() | atom() | integer(), command_args(), options()) ::
          {:ok, term()} | {:error, Container.Error.t()}
  def exec(container, command, opts \\ []) do
    {operation_opts, cli_opts} = exec_operation_opts(opts)
    Command.dispatch([:exec], [container | List.wrap(command)], cli_opts, operation_opts)
  end

  @doc """
  Exports a stopped container's filesystem.

  `container` is passed as the container identifier and `opts` are encoded as
  CLI flags.

  ## Examples

      Container.export("web", output: "web.tar")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container export` as CLI flags.
  """
  @spec export(String.t() | atom() | integer(), options()) ::
          {:ok, term()} | {:error, Container.Error.t()}
  def export(container, opts \\ []) do
    Command.dispatch([:export], [container], opts)
  end

  @doc """
  Fetches logs for a container.

  `container` is passed as the container identifier and `opts` are encoded as
  CLI flags.

  ## Examples

      Container.logs("web")
      Container.logs("web", tail: 50)

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container logs` as CLI flags.
  """
  @spec logs(String.t() | atom() | integer(), options()) ::
          {:ok, term()} | {:error, Container.Error.t()}
  def logs(container, opts \\ []) do
    Command.dispatch([:logs], [container], opts)
  end

  @doc """
  Inspects one or more containers and decodes the JSON response.

  `containers` may be a single container identifier or a list of identifiers,
  and `opts` are encoded as CLI flags.

  ## Examples

      Container.inspect("web")
      Container.inspect(["web", "worker"])

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container inspect` as CLI flags.
  """
  @spec inspect(identifiers(), options()) :: {:ok, term()} | {:error, Container.Error.t()}
  def inspect(containers, opts \\ []) do
    Command.dispatch([:inspect], List.wrap(containers), opts, output: :json)
  end

  @doc """
  Retrieves container statistics.

  `containers` may be a single container identifier or a list of identifiers,
  and `opts` are encoded as CLI flags. In collect mode this defaults to
  `--no-stream` and JSON output unless the caller already provided
  `:no_stream`.

  ## Examples

      Container.stats()
      Container.stats("web")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container stats` as CLI flags.
  """
  @spec stats(identifiers(), options()) :: {:ok, term()} | {:error, Container.Error.t()}
  def stats(containers \\ [], opts \\ []) do
    op_opts =
      opts
      |> Command.json_output_opts()
      |> Command.ensure_option(opts, :no_stream, true)

    Command.dispatch([:stats], List.wrap(containers), opts, op_opts)
  end

  @doc """
  Removes stopped containers.

  `opts` are encoded as CLI flags.

  ## Examples

      Container.prune()

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container prune` as CLI flags.
  """
  @spec prune(options()) :: {:ok, term()} | {:error, Container.Error.t()}
  def prune(opts \\ []) do
    Command.dispatch([:prune], [], opts)
  end

  defp exec_operation_opts(opts) do
    {stdin, opts} = Keyword.pop(opts, :stdin)
    {stream, opts} = Keyword.pop(opts, :stream, false)

    operation_opts =
      []
      |> Command.put_stdin(normalize_stdin(stdin))
      |> Command.put_mode(if(stream, do: :stream, else: :collect))

    {operation_opts, opts}
  end

  defp normalize_stdin(nil), do: nil
  defp normalize_stdin(stdin), do: IO.iodata_to_binary(stdin)
end
