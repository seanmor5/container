# Container

Elixir library for programmatically interacting with Apple's [`container`](https://github.com/apple/container) implementation.

## Installation

Add `:container` to your dependencies:

```elixir
  defp deps do
    [
      # ...
      {:container, "~> 0.1"}
    ]
  end
```

## Examples

```elixir
Container.run("nginx:latest", name: "web", detach: true)
Container.list(all: true)
Container.inspect(["web"])
Container.exec("web", ["cat"], stdin: "hello\n")
Container.logs("web", tail: 50)
Container.copy("web:/var/log/nginx/access.log", "./access.log")

Container.Image.pull("alpine:latest", platform: "linux/arm64")
Container.Registry.login("ghcr.io", username: "sean", password_stdin: "secret")
Container.System.version()

Container.Machine.create("alpine:3.22", name: "dev", memory: "4G")
Container.Machine.run(["uname", "-a"], name: "dev")

{:ok, session} =
  Container.exec("web", ["codex", "app-server"], stream: true, interactive: true)

:ok = Container.Exec.write(session, "{\"jsonrpc\":\"2.0\"}\n")
{:ok, chunk} = Container.Exec.read(session, 5_000)
:ok = Container.Exec.close_stdin(session)
```

Pulls, pushes, runs, and machine creates default to `--progress none` so a
progress bar is not mixed into captured output. Builds default to
`--progress plain`. Pass `progress: "auto"` to keep the CLI default.

`container build`, `container builder`, `commit`, `clean`, and `cluster` are
CLI plugins. Run `container system start` before using them. `container cluster`
is experimental and was renamed from `container k8s` in Apple container 1.6.1.

## Motivation

I have Mac Minis that need to be utilized.

## License

Copyright (c) 2026 Sean Moriarity

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.