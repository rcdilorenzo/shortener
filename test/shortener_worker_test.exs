defmodule ShortenerWorkerTest do
  use ExUnit.Case

  setup do
    table = :ets.new(:urls, [:set, :public])
    {:ok, worker1} = Shortener.Worker.start_link(table)
    {:ok, worker2} = Shortener.Worker.start_link(table)
    {:ok, table: table, w1: worker1, w2: worker2}
  end

  test "reading a shortened url from any worker", state do
    %{table: table, w1: worker1, w2: worker2} = state
    :ets.insert(table, {"gl", "http://google.com"})
    assert {:ok, "http://google.com"} == Shortener.Worker.url(worker1, "gl")
    assert {:ok, "http://google.com"} == Shortener.Worker.url(worker2, "gl")
  end
end
