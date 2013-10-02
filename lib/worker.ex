defmodule Worker do
  def worker(collector_id) do
    receive do
      { :request, verb, url } ->
        { time, { status, content } } = make_timed_request(verb, url)
        collector_id <- { :response, { time / 1000, status }, content }

        worker(collector_id)
    end
  end

  defp make_timed_request(verb, url) do
    :timer.tc fn -> do_request(verb, url) end
  end

  defp do_request(verb, url) do
    convert_url = fn url ->  String.to_char_list! url end
    { :ok, { { _protocol, status_code, _status_phrase }, _headers, content } } =
      :httpc.request verb, { convert_url.(url), [] }, [], []
    { status_code, content }
  end
end
