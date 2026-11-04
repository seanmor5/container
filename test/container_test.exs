defmodule ContainerTest do
  use ExUnit.Case, async: true

  alias Container.Error
  alias Container.Exec
  alias Container.Operation
  alias Container.Transport.CLI

  defmodule CaptureTransport do
    @behaviour Container.Transport

    @impl true
    def execute(operation, _opts), do: {:ok, operation}
  end

  describe "public API shape" do
    test "run mirrors the CLI arguments" do
      assert {:ok, %Operation{} = operation} =
               Container.run("nginx:latest", ["/bin/sh"],
                 name: "web",
                 detach: true,
                 transport: CaptureTransport
               )

      assert operation.command == ["run"]
      assert operation.args == ["nginx:latest", "/bin/sh"]
      assert operation.opts == [progress: "none", name: "web", detach: true]
      assert operation.output == :raw
    end

    test "run treats a keyword list as options" do
      assert {:ok, %Operation{} = operation} =
               Container.run("nginx:latest", detach: true, transport: CaptureTransport)

      assert operation.args == ["nginx:latest"]
      assert Keyword.get(operation.opts, :detach) == true
    end

    test "build treats a keyword list as options and quiets progress" do
      assert {:ok, %Operation{} = operation} =
               Container.build(tag: "app:latest", transport: CaptureTransport)

      assert operation.command == ["build"]
      assert operation.args == ["."]
      assert Keyword.get(operation.opts, :tag) == "app:latest"
      assert Keyword.get(operation.opts, :progress) == "plain"
    end

    test "caller progress is preserved" do
      assert {:ok, %Operation{} = operation} =
               Container.Image.pull("alpine:latest",
                 progress: "auto",
                 transport: CaptureTransport
               )

      assert operation.opts == [progress: "auto"]
    end

    test "stop treats a keyword list as options" do
      assert {:ok, %Operation{} = operation} =
               Container.stop(all: true, transport: CaptureTransport)

      assert operation.command == ["stop"]
      assert operation.args == []
      assert operation.opts == [all: true]
    end

    test "list defaults to JSON output for structured results" do
      assert {:ok, %Operation{} = operation} =
               Container.list(all: true, transport: CaptureTransport)

      assert operation.command == ["list"]
      assert operation.opts == [all: true]
      assert operation.output == :json
      assert operation.output_flag == true
    end

    test "inspect decodes implicit JSON output" do
      assert {:ok, %Operation{} = operation} =
               Container.inspect(["web"], transport: CaptureTransport)

      assert operation.command == ["inspect"]
      assert operation.args == ["web"]
      assert operation.output == :json
      assert operation.output_flag == false
    end

    test "stats defaults to JSON and no-stream" do
      assert {:ok, %Operation{} = operation} =
               Container.stats(["web"], transport: CaptureTransport)

      assert operation.opts == [no_stream: true]
      assert operation.output == :json
    end

    test "stats defaults to no-stream in collect mode and keeps caller flags" do
      assert {:ok, %Operation{} = operation} =
               Container.stats(["web"], format: "yaml", transport: CaptureTransport)

      assert operation.command == ["stats"]
      assert operation.opts == [format: "yaml", no_stream: true]
      assert operation.output == :raw
    end

    test "stats streams when no_stream is false" do
      assert {:ok, %Operation{} = operation} =
               Container.stats("web", no_stream: false, transport: CaptureTransport)

      assert operation.mode == :stream
      assert Keyword.get(operation.opts, :no_stream) == false
      assert operation.output == :raw
    end

    test "logs encodes tail and streams when following" do
      assert {:ok, %Operation{} = operation} =
               Container.logs("web", tail: 50, follow: true, transport: CaptureTransport)

      assert operation.mode == :stream
      assert operation.opts == [tail: 50, follow: true]
    end

    test "new lifecycle commands mirror the CLI" do
      assert {:ok, %Operation{command: ["commit"], args: ["web", "web:snap"]}} =
               Container.commit("web", "web:snap", transport: CaptureTransport)

      assert {:ok, %Operation{command: ["copy"], args: ["web:/etc/hosts", "./hosts"]}} =
               Container.copy("web:/etc/hosts", "./hosts", transport: CaptureTransport)

      assert {:ok, %Operation{command: ["clean"], args: ["web", "worker"]}} =
               Container.clean(["web", "worker"], transport: CaptureTransport)
    end

    test "machine and cluster commands hyphenate subcommands" do
      assert {:ok, %Operation{} = machine} =
               Container.Machine.set([cpus: 4, home_mount: "ro"],
                 name: "dev",
                 transport: CaptureTransport
               )

      assert machine.command == ["machine", "set"]
      assert machine.args == ["cpus=4", "home-mount=ro"]
      assert Keyword.get(machine.opts, :name) == "dev"

      assert {:ok, %Operation{command: ["machine", "set-default"], args: ["dev"]}} =
               Container.Machine.set_default("dev", transport: CaptureTransport)

      assert {:ok, %Operation{command: ["cluster", "write-config"]}} =
               Container.Cluster.write_config(name: "dev", transport: CaptureTransport)

      assert {:ok, %Operation{} = logs} =
               Container.Machine.logs(follow: true, tail: 10, transport: CaptureTransport)

      assert logs.command == ["machine", "logs"]
      assert logs.args == []
      assert logs.mode == :stream
    end

    test "dns list requests JSON" do
      assert {:ok, %Operation{} = operation} =
               Container.System.DNS.list(transport: CaptureTransport)

      assert operation.command == ["system", "dns", "list"]
      assert operation.output == :json
      assert operation.output_flag == true
    end

    test "registry login sends password over stdin when provided" do
      assert {:ok, %Operation{} = operation} =
               Container.Registry.login(
                 "ghcr.io",
                 username: "sean",
                 password_stdin: "secret",
                 transport: CaptureTransport
               )

      assert operation.command == ["registry", "login"]
      assert operation.args == ["ghcr.io"]
      assert Keyword.get(operation.opts, :username) == "sean"
      assert Keyword.get(operation.opts, :password_stdin) == true
      assert operation.stdin == "secret"
    end

    test "exec accepts one-shot stdin" do
      assert {:ok, %Operation{} = operation} =
               Container.exec("web", ["cat"],
                 stdin: "ping\n",
                 transport: CaptureTransport
               )

      assert operation.command == ["exec"]
      assert operation.args == ["web", "cat"]
      assert operation.stdin == "ping\n"
      assert operation.mode == :collect
    end

    test "exec enables interactive mode with stream: true" do
      assert {:ok, %Operation{} = operation} =
               Container.exec("web", ["codex", "app-server"],
                 stream: true,
                 transport: CaptureTransport
               )

      assert operation.command == ["exec"]
      assert operation.args == ["web", "codex", "app-server"]
      assert operation.mode == :stream
    end
  end

  describe "CLI transport" do
    test "encodes options and decodes JSON when format is supported" do
      runner = fn executable, argv, stdin ->
        assert executable == "container"
        assert stdin == nil
        assert argv == ["list", "--all", "--format", "json"]

        {:ok, %{stdout: ~s([{"id":"web"}]), stderr: "", exit_status: 0}}
      end

      operation = %Operation{
        command: ["list"],
        args: [],
        opts: [all: true],
        output: :json,
        output_flag: true
      }

      assert {:ok, [%{"id" => "web"}]} = CLI.execute(operation, runner: runner)
    end

    test "decodes implicit JSON commands without adding format flags" do
      runner = fn _executable, argv, _stdin ->
        assert argv == ["inspect", "web"]
        %{stdout: ~s([{"id":"web"}]), stderr: "", exit_status: 0}
      end

      operation = %Operation{
        command: ["inspect"],
        args: ["web"],
        opts: [],
        output: :json,
        output_flag: false
      }

      assert {:ok, [%{"id" => "web"}]} = CLI.execute(operation, runner: runner)
    end

    test "repeats list and keyword options using CLI flags" do
      runner = fn _executable, argv, _stdin ->
        assert argv == [
                 "build",
                 "--tag",
                 "app:latest",
                 "--tag",
                 "app:stable",
                 "--label",
                 "team=platform",
                 "--label",
                 "service=container",
                 "."
               ]

        %{stdout: "ok", stderr: "", exit_status: 0}
      end

      operation = %Operation{
        command: ["build"],
        args: ["."],
        opts: [tag: ["app:latest", "app:stable"], label: [team: "platform", service: "container"]]
      }

      assert {:ok, %Container.Result{stdout: "ok"}} = CLI.execute(operation, runner: runner)
    end

    test "passes stdin through the runner" do
      runner = fn _executable, argv, stdin ->
        assert argv == ["registry", "login", "--password-stdin", "ghcr.io"]
        assert stdin == "secret"
        %{stdout: "", stderr: "", exit_status: 0}
      end

      operation = %Operation{
        command: ["registry", "login"],
        args: ["ghcr.io"],
        opts: [password_stdin: true],
        stdin: "secret"
      }

      assert {:ok, %Container.Result{}} = CLI.execute(operation, runner: runner)
    end

    test "encodes short-only flags" do
      runner = fn _executable, argv, _stdin ->
        assert argv == ["logs", "--follow", "-n", "50", "web"]
        %{stdout: "", stderr: "", exit_status: 0}
      end

      operation = %Operation{
        command: ["logs"],
        args: ["web"],
        opts: [follow: true, tail: 50]
      }

      assert {:ok, %Container.Result{}} = CLI.execute(operation, runner: runner)
    end

    test "encodes volume size as -s" do
      runner = fn _executable, argv, _stdin ->
        assert argv == ["volume", "create", "-s", "10g", "app-data"]
        %{stdout: "", stderr: "", exit_status: 0}
      end

      operation = %Operation{
        command: ["volume", "create"],
        args: ["app-data"],
        opts: [size: "10g"]
      }

      assert {:ok, %Container.Result{}} = CLI.execute(operation, runner: runner)
    end

    test "captures stderr separately and passes stdin without a temp file" do
      before = Path.wildcard(Path.join(System.tmp_dir!(), "container-*.stdin"))

      assert {:error, %Error{} = error} =
               CLI.execute(
                 %Operation{
                   command: ["-c"],
                   args: ["printf 'out'; printf 'secret-err' >&2; exit 3"],
                   opts: []
                 },
                 command: "/bin/sh"
               )

      assert error.exit_status == 3
      assert error.stdout == "out"
      assert error.stderr == "secret-err"
      assert error.message =~ "secret-err"

      assert {:ok, %{stdout: "secret", stderr: "", exit_status: 0}} =
               CLI.run_command("/bin/sh", ["-c", "cat"], "secret")

      assert Path.wildcard(Path.join(System.tmp_dir!(), "container-*.stdin")) == before
    end

    test "returns a structured error on non-zero exit" do
      runner = fn _executable, _argv, _stdin ->
        %{stdout: "permission denied", stderr: "", exit_status: 1}
      end

      operation = %Operation{command: ["system", "start"], args: [], opts: []}

      assert {:error, %Error{} = error} = CLI.execute(operation, runner: runner)
      assert error.exit_status == 1
      assert error.stdout == "permission denied"
      assert error.command == ["container", "system", "start"]
    end

    test "stream mode returns a session that can exchange stdin/stdout" do
      operation = %Operation{
        command: ["-c"],
        args: [
          "while IFS= read -r line; do printf 'reply:%s\\n' \"$line\"; [ \"$line\" = quit ] && exit 0; done"
        ],
        opts: [],
        mode: :stream
      }

      assert {:ok, %Exec{} = session} = CLI.execute(operation, command: "/bin/sh")
      assert :ok = Exec.write(session, "ping\n")
      assert {:ok, "reply:ping\n"} = Exec.read(session, 1_000)
      assert :ok = Exec.write(session, "quit\n")
      assert {:ok, "reply:quit\n"} = Exec.read(session, 1_000)
      assert :eof = Exec.read(session, 1_000)

      assert {:ok, %Container.Result{exit_status: 0, stderr: ""}} =
               Exec.await_exit(session, 1_000)
    end

    test "stream mode surfaces stderr and exit status on failure" do
      operation = %Operation{
        command: ["-c"],
        args: ["echo boom 1>&2; exit 7"],
        opts: [],
        mode: :stream
      }

      assert {:ok, %Exec{} = session} = CLI.execute(operation, command: "/bin/sh")
      assert :eof = Exec.read(session, 1_000)

      assert {:error, %Error{} = error} = Exec.await_exit(session, 1_000)
      assert error.exit_status == 7
      assert error.stderr == "boom\n"
      assert error.command == ["/bin/sh", "-c", "echo boom 1>&2; exit 7"]
    end

    test "close_stdin sends EOF without closing stdout" do
      operation = %Operation{
        command: ["-c"],
        args: ["cat"],
        opts: [],
        mode: :stream
      }

      assert {:ok, %Exec{} = session} = CLI.execute(operation, command: "/bin/sh")
      assert :ok = Exec.write(session, "hello")
      assert :ok = Exec.close_stdin(session)
      assert {:ok, "hello"} = Exec.read(session, 2_000)
      assert :eof = Exec.read(session, 2_000)

      assert {:ok, %Container.Result{exit_status: 0}} = Exec.await_exit(session, 2_000)
      assert {:error, :closed} = Exec.write(session, "again")
    end
  end
end
