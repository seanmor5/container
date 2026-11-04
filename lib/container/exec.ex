defmodule Container.Exec do
  @moduledoc """
  Interactive session for streamed `container exec` commands.

  Sessions keep the child process alive, allow incremental writes to stdin,
  and expose stdout chunks through blocking reads.

  You usually obtain a session by calling `Container.exec/3` with
  `stream: true`:

      {:ok, session} =
        Container.exec("web", ["sh"], stream: true, interactive: true)

      :ok = Container.Exec.write(session, "echo hello\\n")
      {:ok, chunk} = Container.Exec.read(session, 5_000)
      {:ok, result} = Container.Exec.await_exit(session, 5_000)

  `read/2` returns stdout chunks as they arrive. Once the process exits and
  all buffered output has been consumed, `read/2` returns `:eof`.

  `await_exit/2` blocks until the child process exits and returns either
  `{:ok, %Container.Result{}}` for a zero exit status or
  `{:error, %Container.Error{}}` for a non-zero exit status.

  `close_stdin/1` closes the write side of stdin so the child observes EOF
  without tearing down stdout. Ports cannot half-close their own stdin, so
  the session writes through a private FIFO instead.
  """

  use GenServer

  alias Container.Error
  alias Container.Result

  @enforce_keys [:pid]
  defstruct [:pid]

  @doc """
  Opens a streamed exec session.

  This is a low-level constructor used by the CLI transport. Most callers
  should use `Container.exec/3` with `stream: true` instead.

  ## Options

    * `:executable` - executable path or name to run

    * `:argv` - argument vector passed to the executable

    * `:command` - full command representation stored in the exit result

    * `:stdin` - optional initial stdin written after the process starts
  """
  def open(opts) do
    case GenServer.start_link(__MODULE__, opts) do
      {:ok, pid} -> {:ok, %__MODULE__{pid: pid}}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Writes data to the session's stdin.

  `data` is converted to a binary before being written.

  ## Examples

      :ok = Container.Exec.write(session, "echo hello\\n")

  Returns `:ok` on success or `{:error, reason}` if the session is closed
  or the write fails.
  """
  def write(%__MODULE__{pid: pid}, data) do
    safe_call(pid, {:write, IO.iodata_to_binary(data)})
  end

  @doc """
  Reads the next available stdout chunk.

  `timeout` defaults to `:infinity`. If output is already buffered, the next
  chunk is returned immediately. If the process has exited and all output has
  been consumed, this returns `:eof`.

  ## Examples

      {:ok, chunk} = Container.Exec.read(session, 5_000)
      :eof = Container.Exec.read(session, 5_000)
  """
  def read(%__MODULE__{pid: pid}, timeout \\ :infinity) do
    safe_call(pid, :read, timeout)
  end

  @doc """
  Waits for the child process to exit.

  `timeout` defaults to `:infinity`. On success this returns
  `{:ok, %Container.Result{}}`. If the command exits non-zero, it returns
  `{:error, %Container.Error{}}`.

  ## Examples

      {:ok, result} = Container.Exec.await_exit(session, 5_000)
  """
  def await_exit(%__MODULE__{pid: pid}, timeout \\ :infinity) do
    safe_call(pid, :await_exit, timeout)
  end

  @doc """
  Closes the session and terminates the child process if it is still running.

  ## Examples

      :ok = Container.Exec.close(session)
  """
  def close(%__MODULE__{pid: pid}) do
    safe_call(pid, :close)
  end

  @doc """
  Closes stdin so the child process observes EOF.

  stdout remains open. Further writes return `{:error, :closed}`.

  ## Examples

      :ok = Container.Exec.write(session, "hello")
      :ok = Container.Exec.close_stdin(session)
  """
  def close_stdin(%__MODULE__{pid: pid}) do
    safe_call(pid, :close_stdin)
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
    File.touch!(stderr_path)
    File.chmod!(stderr_path, 0o600)

    {port, stdin_writer, fifo_path} = open_session(executable, argv, stderr_path)
    # Both ends are open, so the directory entry can go. The inode lives
    # until the descriptors close, including if this process dies.
    File.rm(fifo_path)

    if is_binary(stdin) and stdin != "" do
      :ok = write_stdin(stdin_writer, stdin)
    end

    {:ok,
     %{
       port: port,
       stdin_writer: stdin_writer,
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

  def handle_call({:write, _data}, _from, %{stdin_writer: nil} = state) do
    {:reply, {:error, :closed}, state}
  end

  def handle_call({:write, data}, _from, state) do
    {:reply, write_stdin(state.stdin_writer, data), state}
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

  def handle_call(:close_stdin, _from, state) do
    close_stdin_writer(state.stdin_writer)
    {:reply, :ok, %{state | stdin_writer: nil}}
  end

  def handle_call(:close, _from, state) do
    reply_pending(state, :eof, {:error, :closed})
    cleanup_port(state.port)
    close_stdin_writer(state.stdin_writer)
    cleanup_file(state.stderr_path)

    {:stop, :normal, :ok,
     %{
       state
       | port: nil,
         stdin_writer: nil,
         stderr_path: nil,
         pending_reads: [],
         pending_exit_waiters: []
     }}
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

    reply_pending(state, :eof, exit_result)
    close_stdin_writer(state.stdin_writer)
    cleanup_file(state.stderr_path)

    {:noreply,
     %{
       state
       | port: nil,
         stdin_writer: nil,
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
    close_stdin_writer(state[:stdin_writer])
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

  defp open_session(executable, argv, stderr_path) do
    fifo_path = temp_path("fifo")
    File.rm(fifo_path)
    parent = self()

    try do
      {"", 0} = System.cmd("mkfifo", ["-m", "600", fifo_path])
      # The writer owns the FIFO fd. Opening it in this process would deadlock
      # against the reader, and a borrowed fd would close when the opener exited.
      writer = spawn(fn -> stdin_writer(parent, fifo_path) end)
      port = open_port(executable, argv, fifo_path, stderr_path)
      :ok = await_stdin(writer)
      {port, writer, fifo_path}
    rescue
      error ->
        File.rm(fifo_path)
        reraise error, __STACKTRACE__
    end
  end

  defp stdin_writer(parent, fifo_path) do
    ref = Process.monitor(parent)

    case File.open(fifo_path, [:write, :binary, :raw]) do
      {:ok, io} ->
        send(parent, {:stdin_fifo, self(), :ok})
        stdin_loop(io, ref)

      {:error, reason} ->
        send(parent, {:stdin_fifo, self(), {:error, reason}})
    end
  end

  defp stdin_loop(io, ref) do
    receive do
      {:write, from, data} ->
        send(from, {:stdin_write, IO.binwrite(io, data)})
        stdin_loop(io, ref)

      :close ->
        File.close(io)

      {:DOWN, ^ref, _, _, _} ->
        File.close(io)
    end
  end

  defp await_stdin(writer) do
    receive do
      {:stdin_fifo, ^writer, :ok} ->
        :ok

      {:stdin_fifo, ^writer, {:error, reason}} ->
        raise ArgumentError, "could not open stdin fifo: #{inspect(reason)}"
    after
      1_000 ->
        Process.exit(writer, :kill)
        raise ArgumentError, "timed out opening stdin fifo"
    end
  end

  defp write_stdin(writer, data) do
    send(writer, {:write, self(), data})

    receive do
      {:stdin_write, :ok} -> :ok
      {:stdin_write, {:error, reason}} -> {:error, reason}
    after
      5_000 -> {:error, :timeout}
    end
  end

  defp close_stdin_writer(nil), do: :ok

  defp close_stdin_writer(writer) do
    if Process.alive?(writer), do: send(writer, :close)
    :ok
  end

  defp open_port(executable, argv, fifo_path, stderr_path) do
    shell = "/bin/sh"

    shell_argv = [
      "-c",
      "stdin_path=$1; stderr_path=$2; shift 2; exec \"$@\" <\"$stdin_path\" 2>>\"$stderr_path\"",
      "sh",
      fifo_path,
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

  defp reply_pending(state, read_reply, exit_reply) do
    Enum.each(state.pending_reads, &GenServer.reply(&1, read_reply))
    Enum.each(state.pending_exit_waiters, &GenServer.reply(&1, exit_reply))
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
