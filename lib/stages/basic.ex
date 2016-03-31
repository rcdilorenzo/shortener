defmodule Shortener.Basic do
  def start_link do
    spawn_link(__MODULE__, :loop, [%{}])
  end

  def loop(state) do
    receive do
      {:shorten, pid, short, url} ->
        send(pid, :ok)
        loop(Map.put(state, short, url))
      {:url, pid, short} ->
        send(pid, Map.fetch(state, short))
        loop(state)
    end
  end
end
