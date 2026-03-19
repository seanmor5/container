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
      assert operation.opts == [name: "web", detach: true]
      assert operation.output == :raw
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

    test "stats defaults to no-stream in collect mode" do
      assert {:ok, %Operation{} = operation} =
               Container.stats(["web"], transport: CaptureTransport)

      assert operation.command == ["stats"]
      assert operation.opts == [no_stream: true]
      assert operation.output == :json
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

    test "aliases map to the canonical commands" do
      assert {:ok, %Operation{command: ["list"]}} = Container.ls(transport: CaptureTransport)

      assert {:ok, %Operation{command: ["delete"]}} =
               Container.rm("web", transport: CaptureTransport)

      assert {:ok, %Operation{command: ["image", "delete"]}} =
               Container.Image.rm("app:latest", transport: CaptureTransport)
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
  end
end
