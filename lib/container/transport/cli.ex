defmodule Container.Transport.CLI do
  @moduledoc """
  CLI transport for Apple's `container` command.
  """

  @behaviour Container.Transport

  alias Container.Error
  alias Container.Operation
  alias Container.Result

  @impl true
  def execute(%Operation{mode: :stream} = operation, transport_opts) do
    executable = Keyword.get(transport_opts, :command, "container")
    argv = build_argv(operation)
    command = full_command(executable, argv)

    case Container.Exec.open(
           executable: executable,
           argv: argv,
           command: command,
           stdin: operation.stdin
         ) do
      {:ok, session} ->
        {:ok, session}

      {:error, reason} ->
        {:error, Error.transport_failed(reason: reason, command: command)}
    end
  end

  def execute(%Operation{} = operation, transport_opts) do
    executable = Keyword.get(transport_opts, :command, "container")
    runner = Keyword.get(transport_opts, :runner, &__MODULE__.run_command/3)
    argv = build_argv(operation)
    command = full_command(executable, argv)

    with {:ok, %{stdout: stdout, stderr: stderr, exit_status: 0}} <-
           invoke_runner(runner, executable, argv, operation.stdin, command),
         {:ok, value} <- maybe_decode(operation, stdout, command) do
      case operation.output do
        :raw ->
          {:ok, %Result{command: command, stdout: stdout, stderr: stderr, exit_status: 0}}

        :json ->
          {:ok, value}
      end
    else
      {:ok, %{stdout: stdout, stderr: stderr, exit_status: exit_status}} ->
        {:error,
         Error.command_failed(
           command: command,
           exit_status: exit_status,
           stdout: stdout,
           stderr: stderr
         )}

      {:error, %Error{} = error} ->
        {:error, error}
    end
  end

  @doc false
  def run_command(executable, argv, nil) do
    {stdout, exit_status} = System.cmd(executable, argv, stderr_to_stdout: true)
    {:ok, %{stdout: stdout, stderr: "", exit_status: exit_status}}
  rescue
    error -> {:error, error}
  end

  def run_command(executable, argv, stdin) when is_binary(stdin) do
    path = temp_path()

    try do
      File.write!(path, stdin)

      {stdout, exit_status} =
        System.cmd(
          "/bin/sh",
          ["-c", "input=$1; shift; cat \"$input\" | exec \"$@\"", "sh", path, executable | argv],
          stderr_to_stdout: true
        )

      {:ok, %{stdout: stdout, stderr: "", exit_status: exit_status}}
    rescue
      error -> {:error, error}
    after
      File.rm(path)
    end
  end

  defp invoke_runner(runner, executable, argv, stdin, command) do
    case runner.(executable, argv, stdin) do
      {:ok, %{stdout: _stdout, stderr: _stderr, exit_status: _exit_status} = result} ->
        {:ok, result}

      %{stdout: _stdout, stderr: _stderr, exit_status: _exit_status} = result ->
        {:ok, result}

      {:error, reason} ->
        {:error, Error.transport_failed(reason: reason, command: command)}

      other ->
        {:error, Error.transport_failed(reason: other, command: command)}
    end
  end

  defp maybe_decode(%Operation{output: :raw}, _stdout, _command), do: {:ok, nil}

  defp maybe_decode(%Operation{output: :json}, stdout, command) do
    case JSON.decode(stdout) do
      {:ok, value} ->
        {:ok, value}

      {:error, reason} ->
        {:error, Error.invalid_json(command: command, stdout: stdout, reason: reason)}
    end
  rescue
    error -> {:error, Error.invalid_json(command: command, stdout: stdout, reason: error)}
  end

  defp build_argv(%Operation{} = operation) do
    command = operation.command
    opts = maybe_insert_json_format(operation)

    command ++ encode_opts(opts) ++ operation.args
  end

  defp maybe_insert_json_format(%Operation{output: :json, output_flag: true, opts: opts}) do
    if Keyword.has_key?(opts, :format) do
      opts
    else
      opts ++ [format: "json"]
    end
  end

  defp maybe_insert_json_format(%Operation{opts: opts}), do: opts

  defp encode_opts(opts) do
    Enum.flat_map(opts, &encode_opt/1)
  end

  defp encode_opt({_key, nil}), do: []
  defp encode_opt({_key, false}), do: []
  defp encode_opt({key, true}), do: [flag(key)]

  defp encode_opt({key, value}) when is_binary(value) or is_number(value) or is_atom(value) do
    [flag(key), to_string(value)]
  end

  defp encode_opt({key, value}) when is_map(value) do
    value
    |> Map.to_list()
    |> Enum.sort_by(fn {nested_key, _nested_value} -> to_string(nested_key) end)
    |> Enum.flat_map(fn nested -> encode_opt({key, [nested]}) end)
  end

  defp encode_opt({key, value}) when is_list(value) do
    cond do
      value == [] ->
        []

      keyword_list?(value) ->
        Enum.flat_map(value, fn {nested_key, nested_value} ->
          [flag(key), "#{nested_key}=#{nested_value}"]
        end)

      true ->
        Enum.flat_map(value, fn item ->
          case item do
            {nested_key, nested_value} ->
              [flag(key), "#{nested_key}=#{nested_value}"]

            _other ->
              [flag(key), to_string(item)]
          end
        end)
    end
  end

  defp flag(key) do
    "--" <> (key |> to_string() |> String.replace("_", "-"))
  end

  defp keyword_list?(list) do
    Enum.all?(list, fn
      {key, _value} when is_atom(key) or is_binary(key) -> true
      _other -> false
    end)
  end

  defp full_command(executable, argv), do: [to_string(executable) | argv]

  defp temp_path do
    Path.join(
      System.tmp_dir!(),
      "container-#{System.unique_integer([:positive, :monotonic])}.stdin"
    )
  end
end
