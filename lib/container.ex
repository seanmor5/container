defmodule Container do
  @moduledoc """
  Programmatic interface for Apple's `container` CLI.

  The public API mirrors the CLI shape closely. Each command builds a
  `%Container.Operation{}` and dispatches it through a configurable transport.
  """

  alias Container.Command
  alias Container.Operation

  @type command_args :: [String.t() | atom() | integer()]
  @type identifiers :: String.t() | atom() | integer() | [String.t() | atom() | integer()]
  @type option :: {atom(), term()}
  @type options :: [option()]

  @doc """
  Executes a prepared operation through the configured transport.
  """
  @spec execute(Operation.t(), keyword()) :: {:ok, term()} | {:error, Container.Error.t()}
  def execute(%Operation{} = operation, exec_opts \\ []) do
    transport = Keyword.get(exec_opts, :transport, default_transport())
    transport_opts = Keyword.get(exec_opts, :transport_opts, default_transport_opts())

    transport.execute(operation, transport_opts)
  end

  @doc """
  Runs a container from an image.
  """
  @spec run(String.t(), command_args(), options()) ::
          {:ok, term()} | {:error, Container.Error.t()}
  def run(image, command \\ [], opts \\ []) do
    Command.dispatch([:run], [image | List.wrap(command)], opts)
  end

  @doc """
  Builds an image from a local build context.
  """
  @spec build(String.t(), options()) :: {:ok, term()} | {:error, Container.Error.t()}
  def build(context \\ ".", opts \\ []) do
    Command.dispatch([:build], [context], opts)
  end

  @doc """
  Creates a container from an image without starting it.
  """
  @spec create(String.t(), command_args(), options()) ::
          {:ok, term()} | {:error, Container.Error.t()}
  def create(image, command \\ [], opts \\ []) do
    Command.dispatch([:create], [image | List.wrap(command)], opts)
  end

  @doc """
  Starts a stopped container.
  """
  @spec start(String.t() | atom() | integer(), options()) ::
          {:ok, term()} | {:error, Container.Error.t()}
  def start(container, opts \\ []) do
    Command.dispatch([:start], [container], opts)
  end

  @doc """
  Stops one or more containers.
  """
  @spec stop(identifiers(), options()) :: {:ok, term()} | {:error, Container.Error.t()}
  def stop(containers \\ [], opts \\ []) do
    Command.dispatch([:stop], List.wrap(containers), opts)
  end

  @doc """
  Sends a signal to one or more running containers.
  """
  @spec kill(identifiers(), options()) :: {:ok, term()} | {:error, Container.Error.t()}
  def kill(containers \\ [], opts \\ []) do
    Command.dispatch([:kill], List.wrap(containers), opts)
  end

  @doc """
  Deletes one or more containers.
  """
  @spec delete(identifiers(), options()) :: {:ok, term()} | {:error, Container.Error.t()}
  def delete(containers \\ [], opts \\ []) do
    Command.dispatch([:delete], List.wrap(containers), opts)
  end

  @doc """
  Alias for `delete/2`.
  """
  @spec rm(identifiers(), options()) :: {:ok, term()} | {:error, Container.Error.t()}
  def rm(containers \\ [], opts \\ []) do
    delete(containers, opts)
  end

  @doc """
  Lists containers.
  """
  @spec list(options()) :: {:ok, term()} | {:error, Container.Error.t()}
  def list(opts \\ []) do
    Command.dispatch([:list], [], opts, Command.json_output_opts(opts))
  end

  @doc """
  Alias for `list/1`.
  """
  @spec ls(options()) :: {:ok, term()} | {:error, Container.Error.t()}
  def ls(opts \\ []) do
    list(opts)
  end

  @doc """
  Executes a process inside a running container.
  """
  @spec exec(String.t() | atom() | integer(), command_args(), options()) ::
          {:ok, term()} | {:error, Container.Error.t()}
  def exec(container, command, opts \\ []) do
    {operation_opts, cli_opts} = exec_operation_opts(opts)
    Command.dispatch([:exec], [container | List.wrap(command)], cli_opts, operation_opts)
  end

  @doc """
  Exports a stopped container's filesystem.
  """
  @spec export(String.t() | atom() | integer(), options()) ::
          {:ok, term()} | {:error, Container.Error.t()}
  def export(container, opts \\ []) do
    Command.dispatch([:export], [container], opts)
  end

  @doc """
  Fetches logs for a container.
  """
  @spec logs(String.t() | atom() | integer(), options()) ::
          {:ok, term()} | {:error, Container.Error.t()}
  def logs(container, opts \\ []) do
    Command.dispatch([:logs], [container], opts)
  end

  @doc """
  Inspects one or more containers and decodes the JSON response.
  """
  @spec inspect(identifiers(), options()) :: {:ok, term()} | {:error, Container.Error.t()}
  def inspect(containers, opts \\ []) do
    Command.dispatch([:inspect], List.wrap(containers), opts, output: :json)
  end

  @doc """
  Retrieves container statistics.

  In collect mode this defaults to `--no-stream` and JSON output.
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
  """
  @spec prune(options()) :: {:ok, term()} | {:error, Container.Error.t()}
  def prune(opts \\ []) do
    Command.dispatch([:prune], [], opts)
  end

  defp default_transport do
    Application.get_env(:container, :transport, Container.Transport.CLI)
  end

  defp default_transport_opts do
    Application.get_env(:container, :transport_opts, [])
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
