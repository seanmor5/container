defmodule Container.Command do
  @moduledoc false

  alias Container.Operation

  @reserved_opts [:transport, :transport_opts]

  # Scripted calls should not inherit a TTY progress bar. `build` does not
  # accept `none`; `plain` is its non-interactive progress type.
  @progress_defaults %{
    ["run"] => "none",
    ["build"] => "plain",
    ["image", "pull"] => "none",
    ["image", "push"] => "none",
    ["machine", "create"] => "none"
  }

  def dispatch(command, args \\ [], opts \\ [], operation_opts \\ []) do
    {cli_opts, exec_opts} = split_exec_opts(opts)
    cli_opts = put_default_progress(command, cli_opts)

    command
    |> Operation.new(args, cli_opts, operation_opts)
    |> execute(exec_opts)
  end

  @doc false
  def take_keyword_opts(arg, []) when is_list(arg) do
    if Keyword.keyword?(arg) do
      {[], arg}
    else
      {arg, []}
    end
  end

  def take_keyword_opts(arg, opts), do: {arg, opts}

  @doc false
  def take_build_context(context, []) when is_list(context) do
    if Keyword.keyword?(context) do
      {".", context}
    else
      {context, []}
    end
  end

  def take_build_context(context, opts), do: {context, opts}

  @doc false
  def pop_session_opts(opts) do
    {stdin, opts} = Keyword.pop(opts, :stdin)
    {stream, opts} = Keyword.pop(opts, :stream, false)

    operation_opts =
      []
      |> put_stdin(normalize_stdin(stdin))
      |> put_mode(if(stream, do: :stream, else: :collect))

    {operation_opts, opts}
  end

  @doc false
  def log_operation_opts(opts) do
    stream = Keyword.get(opts, :stream, Keyword.get(opts, :follow, false))
    pop_session_opts(Keyword.put(opts, :stream, stream))
  end

  def json_output_opts(opts, output_flag \\ true) do
    case Keyword.get(opts, :format) do
      nil ->
        if Keyword.get(opts, :quiet, false) do
          []
        else
          [output: :json, output_flag: output_flag]
        end

      :json ->
        [output: :json, output_flag: output_flag]

      "json" ->
        [output: :json, output_flag: output_flag]

      _other ->
        []
    end
  end

  def ensure_option(operation_opts, cli_opts, key, value) do
    if Keyword.has_key?(cli_opts, key) do
      operation_opts
    else
      nested_opts = Keyword.get(operation_opts, :opts, [])
      Keyword.put(operation_opts, :opts, Keyword.put(nested_opts, key, value))
    end
  end

  def put_stdin(operation_opts, nil), do: operation_opts
  def put_stdin(operation_opts, stdin), do: Keyword.put(operation_opts, :stdin, stdin)

  def put_mode(operation_opts, nil), do: operation_opts
  def put_mode(operation_opts, mode), do: Keyword.put(operation_opts, :mode, mode)

  def split_exec_opts(opts) do
    {exec_pairs, cli_pairs} = Enum.split_with(opts, fn {key, _value} -> key in @reserved_opts end)

    exec_opts =
      Enum.reduce(exec_pairs, [], fn
        {:transport, value}, acc -> Keyword.put(acc, :transport, value)
        {:transport_opts, value}, acc -> Keyword.put(acc, :transport_opts, value)
      end)

    {cli_pairs, exec_opts}
  end

  def normalize_stdin(nil), do: nil
  def normalize_stdin(stdin), do: IO.iodata_to_binary(stdin)

  defp put_default_progress(command, opts) do
    case Map.get(@progress_defaults, command_key(command)) do
      nil ->
        opts

      progress ->
        if Keyword.has_key?(opts, :progress) do
          opts
        else
          Keyword.put(opts, :progress, progress)
        end
    end
  end

  defp command_key(command) do
    Enum.map(command, &to_string/1)
  end

  defp execute(%Operation{} = operation, exec_opts) do
    transport = Keyword.get(exec_opts, :transport, default_transport())
    transport_opts = Keyword.get(exec_opts, :transport_opts, default_transport_opts())

    transport.execute(operation, transport_opts)
  end

  defp default_transport do
    Application.get_env(:container, :transport, Container.Transport.CLI)
  end

  defp default_transport_opts do
    Application.get_env(:container, :transport_opts, [])
  end
end
