# Container

Elixir library for programmatically interacting with Apple's [`container`](https://github.com/apple/container) implementation.

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

## Motivation

I have Mac Minis that need to be utilized.

## License

Copyright (c) 2026 Sean Moriarity

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.