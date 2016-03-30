defmodule Shortener do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = if config(:server), do: [
      supervisor(Shortener.TCP.Supervisor, [config(:port, 3000)]),
      supervisor(Shortener.Worker.Supervisor, [config(:table, :urls)])
    ], else: []

    Supervisor.start_link(children, [name: __MODULE__, strategy: :one_for_one])
  end

  defp config(key, default \\ nil) do
    Application.get_env(:shortener, key, default)
  end
end
