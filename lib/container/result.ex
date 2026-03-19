defmodule Container.Result do
  @moduledoc """
  Raw command result returned by the CLI transport.
  """

  defstruct command: [],
            stdout: "",
            stderr: "",
            exit_status: 0

  @type t :: %__MODULE__{
          command: [String.t()],
          stdout: binary(),
          stderr: binary(),
          exit_status: non_neg_integer()
        }
end
