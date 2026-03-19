defmodule Container.Transport do
  @moduledoc """
  Behaviour for container transports.
  """

  alias Container.Operation

  @callback execute(Operation.t(), keyword()) :: {:ok, term()} | {:error, Container.Error.t()}
end
