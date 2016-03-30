defmodule Shortener.TCP.Supervisor do
  use Supervisor
  alias Shortener.TCP.Connection
  require Logger

  @opts [:binary, packet: :line, active: false, reuseaddr: true, exit_on_close: true]
  @name __MODULE__

  def start_link(port, name \\ @name) do
    Supervisor.start_link(__MODULE__, {name, port}, [name: name])
  end

  def init({name, port}) do
    {:ok, socket} = :gen_tcp.listen(port, @opts)
    Logger.info "Now listening on #{port}"
    Task.start_link(fn -> listen_for_conn(name, socket) end)

    children = [
      worker(Shortener.TCP.Connection, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def listen_for_conn(supervisor, socket) do
    case Process.whereis(supervisor) do
      nil ->
        listen_for_conn(supervisor, socket)
      _ ->
        {:ok, conn} = :gen_tcp.accept(socket)
        start_conn(supervisor, conn)
        listen_for_conn(supervisor, socket)
    end
  end

  def start_conn(supervisor, conn) do
    name = Connection.worker_name(conn)
    case Supervisor.start_child(supervisor, [conn]) do
      {:ok, _} ->
        Logger.info "Connecting #{name}..."
      {:error, reason} ->
        Logger.error inspect(reason)
        :gen_tcp.close(conn)
    end
  end
end
