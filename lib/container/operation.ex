defmodule Container.Operation do
  @moduledoc """
  Semantic representation of a `container` command.
  """

  @enforce_keys [:command]
  defstruct command: [],
            args: [],
            opts: [],
            stdin: nil,
            output: :raw,
            output_flag: false,
            mode: :collect

  @type t :: %__MODULE__{
          command: [String.t()],
          args: [String.t()],
          opts: keyword(),
          stdin: binary() | nil,
          output: :raw | :json,
          output_flag: boolean(),
          mode: :collect | :stream
        }

  @spec new([atom() | String.t()], list(), keyword(), keyword()) :: t()
  def new(command, args \\ [], opts \\ [], operation_opts \\ []) do
    operation_opts = merge_cli_opts(operation_opts)

    %__MODULE__{
      command: Enum.map(command, &to_string/1),
      args: normalize_many(args),
      opts: normalize_opts(Keyword.get(operation_opts, :opts, opts)),
      stdin: Keyword.get(operation_opts, :stdin),
      output: Keyword.get(operation_opts, :output, :raw),
      output_flag: Keyword.get(operation_opts, :output_flag, false),
      mode: Keyword.get(operation_opts, :mode, :collect)
    }
  end

  defp merge_cli_opts(operation_opts) do
    case Keyword.fetch(operation_opts, :opts) do
      {:ok, nested_opts} -> Keyword.put(operation_opts, :opts, nested_opts)
      :error -> operation_opts
    end
  end

  defp normalize_opts(opts) do
    Enum.map(opts, fn {key, value} -> {key, normalize_value(value)} end)
  end

  defp normalize_value(value) when is_map(value) do
    value
    |> Map.to_list()
    |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
    |> Enum.map(fn {key, item} -> {key, item} end)
  end

  defp normalize_value(value), do: value

  defp normalize_many(values) do
    values
    |> List.wrap()
    |> Enum.map(&to_string/1)
  end
end
