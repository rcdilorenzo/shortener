defmodule Shortener.TCP.Connection do
  use GenServer
  require Logger
  alias Shortener.TCP.Handler

  def start_link(conn) do
    Supervisor.start_child(Shortener.Worker.Supervisor, [[name: worker_name(conn)]])
    Task.start_link(fn ->
      Process.register(self(), name(conn))
      loop(conn, worker_name(conn))
    end)
  end

  def loop(conn, worker_name) do
    case :gen_tcp.recv(conn, 0) do
      {:ok, data} ->
        command = clean_input(data)
        result = worker_name(conn) |> Handler.process(command)
        :gen_tcp.send(conn, result <> "\n")
        log_request(conn, command)
        loop(conn, worker_name)
      {:error, error} ->
        Logger.info "[#{worker_name}]: Peer disconnected: #{error}"
        GenServer.stop(worker_name)
    end
  end

  def name(conn), do: String.to_atom("#{__MODULE__}.#{worker_name(conn)}")

  def worker_name(conn) do
    {:ok, {{a, b, c, d}, _}} = :inet.peername(conn)
    :"#{a}.#{b}.#{c}.#{d}"
  end

  defp log_request(socket, command) do
    Logger.info "[#{worker_name socket}]: \"#{command}\""
  end

  defp clean_input(line) do
    String.rstrip(line, ?\n) |> String.rstrip(?\r)
  end
end
