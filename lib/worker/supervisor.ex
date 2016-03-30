defmodule Shortener.Worker.Supervisor do
  use Supervisor
  alias Shortener.TCP.Server

  @name __MODULE__

  def start_link(table_name, name \\ @name) do
    Supervisor.start_link(__MODULE__, table_name, [name: @name])
  end

  def init(table_name) do
    table = :ets.new(table_name, [:set, :public])

    children = [
      worker(Shortener.Worker, [table])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end

