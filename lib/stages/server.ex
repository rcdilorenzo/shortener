defmodule Shortener.Server do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  def init(state) do
    {:ok, state}
  end

  def shorten(pid, url, short) do
    GenServer.call(pid, {:shorten, short, url})
  end

  def url(pid, short) do
    GenServer.call(pid, {:url, short})
  end

  # Callbacks

  def handle_call({:shorten, short, url}, _from, state) do
    case Map.fetch(state, short) do
      :error ->
        {:reply, :ok, Map.put(state, short, url)}
      {:ok, _} ->
        {:reply, {:error, :dupalias}, state}
    end
  end

  def handle_call({:url, short}, _from, state) do
    {:reply, Map.fetch(state, short), state}
  end

end
