defmodule Shortener.TCP.Connection do
  use GenServer
  require Logger
  alias Shortener.TCP.Handler

  def start_link(conn) do
    GenServer.start_link(__MODULE__, conn)
  end

  def start_handler(conn) do
    spawn_link(__MODULE__, :loop, [conn, worker_name(conn)])
  end

  def init(conn) do
    Process.flag(:trap_exit, true)
    start_handler(conn)
    {:ok, conn}
  end

  def handle_info({:EXIT, _pid, :normal}, _conn) do
    exit(:normal)
  end

  def handle_info({:EXIT, _pid, _reason}, conn) do
    Logger.warn "TCP handler exited... restarting"
    :gen_tcp.send(conn, "** Server error\n")
    start_handler(conn)
    {:noreply, conn}
  end

  def loop(conn, worker_name) do
    case :gen_tcp.recv(conn, 0) do
      {:ok, data} ->
        command = clean_input(data)

        # NOTE: This is a sample only to cause a crash.
        if command == "/die", do: command + 1

        result = worker(conn) |> Handler.process(command)
        :gen_tcp.send(conn, result <> "\n")
        log_request(conn, command)
        loop(conn, worker_name)
      {:error, error} ->
        Logger.info "[#{worker_name}]: Peer disconnected - #{error}"
        GenServer.stop(worker_name)
    end
  end

  def worker(conn) do
    name = worker_name(conn)
    case Process.whereis(name) do
      nil ->
        Supervisor.start_child(Shortener.Worker.Supervisor, [[name: name]])
      pid -> pid
    end
  end

  def worker_name(conn) do
    {:ok, {{a, b, c, d}, _}} = :inet.peername(conn)
    :"#{a}.#{b}.#{c}.#{d}"
  end

  defp log_request(conn, command) do
    Logger.info "[#{worker_name conn}]: #{inspect command}"
  end

  defp clean_input(line) do
    String.rstrip(line, ?\n) |> String.rstrip(?\r)
  end
end
