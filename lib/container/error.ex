defmodule Container.Error do
  @moduledoc """
  Error returned when a container operation fails.
  """

  defstruct [:message, :command, :stdout, :stderr, :exit_status, :reason]

  @type t :: %__MODULE__{
          message: String.t(),
          command: [String.t()] | nil,
          stdout: binary() | nil,
          stderr: binary() | nil,
          exit_status: integer() | nil,
          reason: term()
        }

  @doc false
  def command_failed(opts) do
    command = Keyword.get(opts, :command)
    exit_status = Keyword.get(opts, :exit_status)
    stdout = Keyword.get(opts, :stdout, "")
    stderr = Keyword.get(opts, :stderr, "")

    %__MODULE__{
      command: command,
      exit_status: exit_status,
      stdout: stdout,
      stderr: stderr,
      reason: Keyword.get(opts, :reason, :command_failed),
      message: "container command failed (exit #{exit_status}): #{Enum.join(command || [], " ")}"
    }
  end

  @doc false
  def transport_failed(opts) do
    reason = Keyword.fetch!(opts, :reason)
    command = Keyword.get(opts, :command)

    %__MODULE__{
      command: command,
      reason: reason,
      message: "container transport failed: #{format_reason(reason)}"
    }
  end

  @doc false
  def invalid_json(opts) do
    command = Keyword.get(opts, :command)
    stdout = Keyword.get(opts, :stdout, "")
    reason = Keyword.fetch!(opts, :reason)

    %__MODULE__{
      command: command,
      stdout: stdout,
      reason: reason,
      message: "container returned invalid JSON: #{format_reason(reason)}"
    }
  end

  defp format_reason(reason) when is_exception(reason) do
    Exception.message(reason)
  end

  defp format_reason(reason) do
    inspect(reason)
  end
end
