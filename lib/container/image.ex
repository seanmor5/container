defmodule Container.Image do
  @moduledoc """
  Image management commands.

  `Container.Image` wraps the `container image` namespace for listing,
  inspecting, transferring, tagging, and deleting images.
  """

  alias Container.Command

  @doc """
  Lists images and returns decoded JSON when supported.

  `opts` are encoded as CLI flags. Unless `:quiet` or an explicit non-JSON
  `:format` is provided, this command requests JSON output and returns the
  decoded result.

  ## Examples

      Container.Image.list()
      Container.Image.list(all: true)

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container image list`
  as CLI flags.
  """
  def list(opts \\ []) do
    Command.dispatch([:image, :list], [], opts, Command.json_output_opts(opts))
  end

  @doc """
  Pulls an image from a registry.

  `image` is passed as the image reference and `opts` are encoded as CLI
  flags.

  ## Examples

      Container.Image.pull("alpine:latest")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container image pull`
  as CLI flags.
  """
  def pull(image, opts \\ []) do
    Command.dispatch([:image, :pull], [image], opts)
  end

  @doc """
  Pushes an image to a registry.

  `image` is passed as the image reference and `opts` are encoded as CLI
  flags.

  ## Examples

      Container.Image.push("app:latest")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container image push`
  as CLI flags.
  """
  def push(image, opts \\ []) do
    Command.dispatch([:image, :push], [image], opts)
  end

  @doc """
  Saves one or more images.

  `images` may be a single image reference or a list of image references,
  and `opts` are encoded as CLI flags.

  ## Examples

      Container.Image.save("app:latest", output: "app.tar")
      Container.Image.save(["app:latest", "base:latest"], output: "images.tar")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container image save`
  as CLI flags.
  """
  def save(images, opts \\ []) do
    Command.dispatch([:image, :save], List.wrap(images), opts)
  end

  @doc """
  Loads an image from an archive.

  `opts` are encoded as CLI flags.

  ## Examples

      Container.Image.load(input: "app.tar")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container image load`
  as CLI flags.
  """
  def load(opts) when is_list(opts) do
    Command.dispatch([:image, :load], [], opts)
  end

  @doc """
  Tags an image.

  `source` is the existing image reference, `target` is the new tag, and
  `opts` are encoded as CLI flags.

  ## Examples

      Container.Image.tag("app:latest", "app:stable")

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container image tag`
  as CLI flags.
  """
  def tag(source, target, opts \\ []) do
    Command.dispatch([:image, :tag], [source, target], opts)
  end

  @doc """
  Deletes one or more images.

  `images` may be a single image reference or a list of image references,
  and `opts` are encoded as CLI flags.

  ## Examples

      Container.Image.delete("app:latest")
      Container.Image.delete(["app:latest", "base:latest"])

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container image delete`
  as CLI flags.
  """
  def delete(images \\ [], opts \\ []) do
    Command.dispatch([:image, :delete], List.wrap(images), opts)
  end

  @doc """
  Removes unused images.

  `opts` are encoded as CLI flags.

  ## Examples

      Container.Image.prune()

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container image prune`
  as CLI flags.
  """
  def prune(opts \\ []) do
    Command.dispatch([:image, :prune], [], opts)
  end

  @doc """
  Inspects one or more images and decodes the JSON response.

  `images` may be a single image reference or a list of image references,
  and `opts` are encoded as CLI flags.

  ## Examples

      Container.Image.inspect("app:latest")
      Container.Image.inspect(["app:latest", "base:latest"])

  ## Options

    * `:transport` - configure the transport used for execution

    * `:transport_opts` - configure the transport options used for execution

  All other keyword options are passed through to `container image inspect`
  as CLI flags.
  """
  def inspect(images, opts \\ []) do
    Command.dispatch([:image, :inspect], List.wrap(images), opts, output: :json)
  end
end
