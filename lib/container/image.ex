defmodule Container.Image do
  @moduledoc """
  Image management commands.
  """

  alias Container.Command

  def list(opts \\ []) do
    Command.dispatch([:image, :list], [], opts, Command.json_output_opts(opts))
  end

  def ls(opts \\ []) do
    list(opts)
  end

  def pull(image, opts \\ []) do
    Command.dispatch([:image, :pull], [image], opts)
  end

  def push(image, opts \\ []) do
    Command.dispatch([:image, :push], [image], opts)
  end

  def save(images, opts \\ []) do
    Command.dispatch([:image, :save], List.wrap(images), opts)
  end

  def load(opts) when is_list(opts) do
    Command.dispatch([:image, :load], [], opts)
  end

  def tag(source, target, opts \\ []) do
    Command.dispatch([:image, :tag], [source, target], opts)
  end

  def delete(images \\ [], opts \\ []) do
    Command.dispatch([:image, :delete], List.wrap(images), opts)
  end

  def rm(images \\ [], opts \\ []) do
    delete(images, opts)
  end

  def prune(opts \\ []) do
    Command.dispatch([:image, :prune], [], opts)
  end

  def inspect(images, opts \\ []) do
    Command.dispatch([:image, :inspect], List.wrap(images), opts, output: :json)
  end
end
