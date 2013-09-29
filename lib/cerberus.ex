defmodule Cerberus do
  def make_concurrent_requests(verb, url, number) do
    start_http_server
    spawn_workers(verb, url, number)
    collect_responses(number, [])
  end

  def spawn_workers(verb, url, number) do
    fn -> do_spawn_worker(verb, url) end |> Stream.repeatedly |> Enum.take(number)
  end

  def start_http_server do
    :inets.start
  end

  defp do_spawn_worker(verb, url) do
    pid = self
    spawn_link(fn -> worker(pid, verb, url) end)
  end

  defp worker(parent_pid, verb, url) do
    { status, content } = do_request(verb, url)
    parent_pid <- { :response, status, content }
  end

  defp do_request(verb, url) do
    convert = fn url ->  String.to_char_list! url end
     { :ok, { { _protocol, status_code, _status_phrase }, _headers, content } } =
       :httpc.request verb, { convert.(url), [] }, [], []
     { status_code, content }
  end

  defp collect_responses(0, responses) do
    responses
  end
  defp collect_responses(number, responses) do
    receive do
      { :response, status, content } ->
        write_content_to_file(content)
        collect_responses(number - 1, [status|responses])
    end
  end

  defp write_content_to_file(content) do
  end
end

