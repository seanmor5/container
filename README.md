# Container

Elixir library for programmatically interacting with Apple's
[`container`](https://github.com/apple/container) CLI.

The API mirrors the CLI layout as closely as possible.

## Examples

```elixir
Container.run("nginx:latest", [], name: "web", detach: true)
Container.list(all: true)
Container.inspect(["web"])
Container.exec("web", ["cat"], stdin: "hello\n")

Container.Image.pull("alpine:latest", platform: "linux/arm64")
Container.Registry.login("ghcr.io", username: "sean", password_stdin: "secret")
Container.System.version()

{:ok, session} =
  Container.exec("web", ["codex", "app-server"], stream: true, interactive: true)

:ok = Container.Exec.write(session, "{\"jsonrpc\":\"2.0\"}\n")
{:ok, chunk} = Container.Exec.read(session, 5_000)
```

## Transport configuration

By default the library shells out to `container` on the current `PATH`.

```elixir
config :container,
  transport: Container.Transport.CLI,
  transport_opts: [command: "/usr/local/bin/container"]
```
