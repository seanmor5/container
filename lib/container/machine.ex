defmodule Container.Machine do
  @moduledoc """
  Container machine management commands.

  `Container.Machine` wraps the `container machine` namespace. A container
  machine is a persistent Linux environment created from an OCI image, with
  the host home directory mounted and a user that matches the host account.
  """

  alias Container.Command

  @doc """
  Creates a container machine from an image and boots it.

  `image` is the image reference and `opts` are encoded as CLI flags.
  Calls default to `--progress none`. Pass `progress: "auto"` to keep the
  CLI default.

  ## Examples

      Container.Machine.create("alpine:3.22", name: "dev")
      Container.Machine.create("alpine:3.22", cpus: 4, memory: "8G", no_boot: true)

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container machine create`
  as CLI flags.
  """
  def create(image, opts \\ []) do
    Command.dispatch([:machine, :create], [image], opts)
  end

  @doc """
  Runs a command in a container machine, booting it first if needed.

  With no command, the CLI opens an interactive login shell. Pass
  `stream: true` to keep that session open through `Container.Exec`.

  ## Examples

      Container.Machine.run(["uname", "-a"], name: "dev")
      Container.Machine.run(name: "dev", detach: true)

  ## Options

    * `:stdin` - send one-shot stdin to the command in collect mode

    * `:stream` - return a `Container.Exec` session instead of collecting output

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container machine run`
  as CLI flags.
  """
  def run(command \\ [], opts \\ []) do
    {command, opts} = Command.take_keyword_opts(command, opts)
    {operation_opts, opts} = Command.pop_session_opts(opts)
    Command.dispatch([:machine, :run], List.wrap(command), opts, operation_opts)
  end

  @doc """
  Lists container machines and returns decoded JSON when supported.

  ## Examples

      Container.Machine.list()

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container machine list`
  as CLI flags.
  """
  def list(opts \\ []) do
    Command.dispatch([:machine, :list], [], opts, Command.json_output_opts(opts))
  end

  @doc """
  Inspects a container machine and decodes the JSON response.

  Uses the default machine when `id` is omitted.

  ## Examples

      Container.Machine.inspect()
      Container.Machine.inspect("dev")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container machine inspect`
  as CLI flags.
  """
  def inspect(id_or_opts \\ nil, opts \\ []) do
    {id, opts} = split_optional_id(id_or_opts, opts)
    do_inspect(id, opts)
  end

  @doc """
  Sets configuration values on a container machine.

  Changes take effect after the machine is stopped and started again.
  Keyword settings are encoded as positional `key=value` arguments, with
  underscores turned into hyphens. Flags such as `:name` belong in `opts`.

  ## Examples

      Container.Machine.set(cpus: 4, memory: "8G")
      Container.Machine.set([home_mount: "ro"], name: "dev")
      Container.Machine.set(["kernel="])

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container machine set`
  as CLI flags.
  """
  def set(settings, opts \\ []) when is_list(settings) do
    Command.dispatch([:machine, :set], encode_settings(settings), opts)
  end

  @doc """
  Sets the default container machine.

  ## Examples

      Container.Machine.set_default("dev")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container machine set-default`
  as CLI flags.
  """
  def set_default(id, opts \\ []) do
    Command.dispatch([:machine, :set_default], [id], opts)
  end

  @doc """
  Fetches logs from a container machine.

  Uses the default machine when `id` is omitted. `:tail` is encoded as `-n`.
  `follow: true` returns a `Container.Exec` session.

  ## Examples

      Container.Machine.logs("dev", tail: 50)
      Container.Machine.logs(follow: true)

  ## Options

    * `:stream` - return a `Container.Exec` session instead of collecting output

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container machine logs`
  as CLI flags.
  """
  def logs(id_or_opts \\ nil, opts \\ []) do
    {id, opts} = split_optional_id(id_or_opts, opts)
    do_logs(id, opts)
  end

  @doc """
  Stops a running container machine.

  Uses the default machine when `id` is omitted.

  ## Examples

      Container.Machine.stop()
      Container.Machine.stop("dev")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container machine stop`
  as CLI flags.
  """
  def stop(id_or_opts \\ nil, opts \\ []) do
    {id, opts} = split_optional_id(id_or_opts, opts)
    do_stop(id, opts)
  end

  @doc """
  Deletes a container machine, stopping it first if it is running.

  ## Examples

      Container.Machine.delete("dev")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container machine delete`
  as CLI flags.
  """
  def delete(id, opts \\ []) do
    Command.dispatch([:machine, :delete], [id], opts)
  end

  defp do_inspect(id, opts) do
    Command.dispatch([:machine, :inspect], args(id), opts, output: :json)
  end

  defp do_logs(id, opts) do
    {operation_opts, opts} = Command.log_operation_opts(opts)
    Command.dispatch([:machine, :logs], args(id), opts, operation_opts)
  end

  defp do_stop(id, opts) do
    Command.dispatch([:machine, :stop], args(id), opts)
  end

  defp split_optional_id(opts, []) when is_list(opts) do
    if Keyword.keyword?(opts) do
      {nil, opts}
    else
      {opts, []}
    end
  end

  defp split_optional_id(id, opts), do: {id, opts}

  defp args(nil), do: []
  defp args(id), do: [id]

  defp encode_settings(settings) do
    if Keyword.keyword?(settings) do
      Enum.map(settings, fn {key, value} ->
        "#{setting_key(key)}=#{value}"
      end)
    else
      Enum.map(settings, &to_string/1)
    end
  end

  defp setting_key(key) do
    key
    |> to_string()
    |> String.replace("_", "-")
  end
end
