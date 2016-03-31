defmodule Shortener.TCP.Handler do
  defp error(worker) do
    """
    An error occurred handling the command.
    Please check your syntax.
    """ <> process(worker, "/help")
  end

  def process(_worker, "/help") do
    """
    Available commands:
      * /help - display this message
      * /shorten [url] [alias] - shorten a url
      * /url [alias] - get a url by the alias
    """
  end

  def process(worker, "/shorten " <> input) do
    case String.split(input, " ") do
      [url, short] ->
        case Shortener.Worker.shorten(worker, url, short) do
          :ok ->
            "URL shortened!"
          {:error, :dupalias} ->
            "This alias is already being used by a different url."
        end
      _ ->
        error(worker)
    end
  end

  def process(worker, "/url " <> short) do
    case Shortener.Worker.url(worker, short) do
      {:ok, url} -> url
      _ -> "URL does not exist."
    end
  end

  def process(worker, _), do: error(worker)
end
