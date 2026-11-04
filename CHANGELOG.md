# Changelog

## Unreleased

* Add `Container.Machine` for persistent container machines.
* Add `Container.Cluster` for the experimental `container cluster` plugin (`k8s` before 1.6.1).
* Add `Container.commit/3`, `Container.copy/3`, and `Container.clean/2`.
* Encode short-only CLI flags: `:tail` is `-n`, `:size` is `-s`.
* Accept keyword options in place of an empty command or identifier list. `Container.run("nginx", detach: true)`, `Container.build(tag: "app")`, and `Container.stop(all: true)` no longer crash.
* Request JSON from `Container.System.DNS.list/1`, matching the other list commands.
* Keep stderr separate from stdout, and pass stdin through a private FIFO instead of a world-readable temp file.
* Add `Container.Exec.close_stdin/1`. `follow: true` on log commands returns a session instead of blocking forever.
* Default scripted `run`, `pull`, `push`, and `machine create` calls to `--progress none`, and `build` to `--progress plain`.
* Hyphenate command segments, so `set_default` and `write_config` reach the CLI as `set-default` and `write-config`.
* Preserve caller flags when a command also injects defaults such as `--no-stream`.

## v0.1.0

Initial release.
