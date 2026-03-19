defmodule Container.Registry do
  @moduledoc """
  Registry management commands.
  """

  alias Container.Command

  def login(server, opts \\ []) do
    {password_stdin, opts} = Keyword.pop(opts, :password_stdin)

    op_opts =
      []
      |> Command.put_stdin(normalize_password(password_stdin))

    cli_opts =
      case password_stdin do
        nil -> opts
        true -> Keyword.put(opts, :password_stdin, true)
        _binary -> Keyword.put(opts, :password_stdin, true)
      end

    Command.dispatch([:registry, :login], [server], cli_opts, op_opts)
  end

  def logout(server, opts \\ []) do
    Command.dispatch([:registry, :logout], [server], opts)
  end

  def list(opts \\ []) do
    Command.dispatch([:registry, :list], [], opts, Command.json_output_opts(opts))
  end

  defp normalize_password(true), do: nil
  defp normalize_password(nil), do: nil
  defp normalize_password(password), do: to_string(password)
end
