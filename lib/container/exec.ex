defmodule Container.Exec do
  @moduledoc """
  Interactive session for streamed `container exec` commands.

  Sessions keep the child process alive, allow incremental writes to stdin,
  and expose stdout chunks through blocking reads.
  """

  use GenServer

  alias Container.Error
  alias Container.Result

  @enforce_keys [:pid]
  defstruct [:pid]

  def open(opts) do
    case GenServer.start_link(__MODULE__, opts) do
      {:ok, pid} -> {:ok, %__MODULE__{pid: pid}}
      {:error, reason} -> {:error, reason}
    end
  end

  def write(%__MODULE__{pid: pid}, data) do
    safe_call(pid, {:write, IO.iodata_to_binary(data)})
  end

  def read(%__MODULE__{pid: pid}, timeout \\ :infinity) do
    safe_call(pid, :read, timeout)
  end

  def await_exit(%__MODULE__{pid: pid}, timeout \\ :infinity) do
    safe_call(pid, :await_exit, timeout)
  end

  def close(%__MODULE__{pid: pid}) do
    safe_call(pid, :close)
  end

  @impl true
  def init(opts) do
    executable =
      opts
      |> Keyword.fetch!(:executable)
      |> resolve_executable!()

    argv = Keyword.fetch!(opts, :argv)
    command = Keyword.fetch!(opts, :command)
    stdin = Keyword.get(opts, :stdin)
    stderr_path = temp_path("stderr")
    port = open_port(executable, argv, stderr_path)

    if is_binary(stdin) and stdin != "" do
      true = Port.command(port, stdin)
    end

    {:ok,
     %{
       port: port,
       command: command,
       stderr_path: stderr_path,
       output: :queue.new(),
       pending_reads: [],
       pending_exit_waiters: [],
       exit_result: nil
     }}
  rescue
    error -> {:stop, error}
  end

  @impl true
  def handle_call({:write, _data}, _from, %{port: nil} = state) do
    {:reply, {:error, :closed}, state}
  end

  def handle_call({:write, data}, _from, state) do
    reply =
      case Port.command(state.port, data) do
        true -> :ok
        false -> {:error, :closed}
      end

    {:reply, reply, state}
  rescue
    error -> {:reply, {:error, error}, state}
  end

  def handle_call(:read, from, %{output: output} = state) do
    case :queue.out(output) do
      {{:value, data}, remaining_output} ->
        {:reply, {:ok, data}, %{state | output: remaining_output}}

      {:empty, _empty_output} when not is_nil(state.exit_result) ->
        {:reply, :eof, state}

      {:empty, _empty_output} ->
        {:noreply, %{state | pending_reads: state.pending_reads ++ [from]}}
    end
  end

  def handle_call(:await_exit, _from, %{exit_result: exit_result} = state)
      when not is_nil(exit_result) do
    {:reply, exit_result, state}
  end

  def handle_call(:await_exit, from, state) do
    {:noreply, %{state | pending_exit_waiters: state.pending_exit_waiters ++ [from]}}
  end

  def handle_call(:close, _from, state) do
    cleanup_port(state.port)
    cleanup_file(state.stderr_path)
    {:stop, :normal, :ok, %{state | port: nil, stderr_path: nil}}
  end

  @impl true
  def handle_info({port, {:data, data}}, %{port: port} = state) do
    case state.pending_reads do
      [reader | remaining_readers] ->
        GenServer.reply(reader, {:ok, data})
        {:noreply, %{state | pending_reads: remaining_readers}}

      [] ->
        {:noreply, %{state | output: :queue.in(data, state.output)}}
    end
  end

  def handle_info({port, :eof}, %{port: port} = state) do
    {:noreply, state}
  end

  def handle_info({port, {:exit_status, exit_status}}, %{port: port} = state) do
    exit_result = build_exit_result(state.command, exit_status, read_stderr(state.stderr_path))

    Enum.each(state.pending_reads, &GenServer.reply(&1, :eof))
    Enum.each(state.pending_exit_waiters, &GenServer.reply(&1, exit_result))
    cleanup_file(state.stderr_path)

    {:noreply,
     %{
       state
       | port: nil,
         stderr_path: nil,
         pending_reads: [],
         pending_exit_waiters: [],
         exit_result: exit_result
     }}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    cleanup_port(state[:port])
    cleanup_file(state[:stderr_path])
    :ok
  end

  defp safe_call(pid, message, timeout \\ 5_000) do
    GenServer.call(pid, message, timeout)
  catch
    :exit, {:timeout, {GenServer, :call, _details}} -> {:error, :timeout}
    :exit, {:noproc, _details} -> {:error, :closed}
    :exit, reason -> {:error, reason}
  end

  defp resolve_executable!(executable) do
    executable = to_string(executable)

    cond do
      Path.type(executable) == :absolute ->
        executable

      resolved = System.find_executable(executable) ->
        resolved

      true ->
        raise ArgumentError, "could not resolve executable: #{executable}"
    end
  end

  defp open_port(executable, argv, stderr_path) do
    shell = "/bin/sh"

    shell_argv = [
      "-c",
      "stderr_path=$1; shift; exec \"$@\" 2>>\"$stderr_path\"",
      "sh",
      stderr_path,
      executable | argv
    ]

    Port.open({:spawn_executable, String.to_charlist(shell)}, [
      :binary,
      :exit_status,
      :use_stdio,
      :hide,
      :eof,
      {:args, Enum.map(shell_argv, &String.to_charlist/1)}
    ])
  end

  defp build_exit_result(command, 0, stderr) do
    {:ok, %Result{command: command, stdout: "", stderr: stderr, exit_status: 0}}
  end

  defp build_exit_result(command, exit_status, stderr) do
    {:error,
     Error.command_failed(
       command: command,
       exit_status: exit_status,
       stdout: "",
       stderr: stderr
     )}
  end

  defp read_stderr(nil), do: ""

  defp read_stderr(path) do
    case File.read(path) do
      {:ok, stderr} -> stderr
      {:error, _reason} -> ""
    end
  end

  defp cleanup_port(nil), do: :ok

  defp cleanup_port(port) do
    Port.close(port)
    :ok
  rescue
    _error -> :ok
  end

  defp cleanup_file(nil), do: :ok

  defp cleanup_file(path) do
    File.rm(path)
    :ok
  end

  defp temp_path(suffix) do
    Path.join(
      System.tmp_dir!(),
      "container-#{System.unique_integer([:positive, :monotonic])}.#{suffix}"
    )
  end
end
