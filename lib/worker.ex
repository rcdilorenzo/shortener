defmodule Shortener.Worker do
  use GenServer

  def start_link(table, opts \\ []) do
    GenServer.start_link(__MODULE__, table, opts)
  end

  def init(table) do
    {:ok, table}
  end

  def url(pid, short) do
    GenServer.call(pid, {:url, short})
  end

  def shorten(pid, url, short) do
    GenServer.call(pid, {:shorten, url, short})
  end

  # Callbacks

  def handle_call({:url, short}, _from, table) do
    case :ets.lookup(table, short) do
      [{_, url}] -> {:reply, {:ok, url}, table}
      _     -> {:reply, :error, table}
    end
  end

  def handle_call({:shorten, url, short}, _from, table) do
    case :ets.lookup(table, short) do
      [] ->
        :ets.insert(table, {short, url})
        {:reply, :ok, table}
      _ ->
        {:reply, {:error, :dupalias}, table}
    end
  end
end
