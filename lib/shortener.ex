defmodule Shortener do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Shortener.TCP.Supervisor, [1337]),
      supervisor(Shortener.Worker.Supervisor, [:urls])
    ]

    Supervisor.start_link(children, [name: __MODULE__, strategy: :one_for_one])
  end
end
