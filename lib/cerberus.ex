defmodule Cerberus do

  def calculate_results(raw_results) do
    average_response_time = calculate_avg_response_time raw_results
    response_codes = calculate_response_codes raw_results
    { average_response_time, response_codes }
  end

  defp calculate_avg_response_time(results) do
    reducer = fn (result, acc) ->
      { time, _response_code } = result
      acc + time
    end
    (List.flatten(results) |> Enum.reduce(0, reducer)) / Enum.count(results)
  end

  def calculate_response_codes(results) do
    all_codes = List.flatten(results) |> Enum.map fn result ->
      { _time, response_code } = result
      response_code
    end
    uniq_codes = Enum.uniq all_codes
    Enum.map uniq_codes, fn code ->
      { code, Enum.count(all_codes, fn c -> c == code end) }
    end
  end

  def run(n // 1000, verb, url, concurrent_workers // 2) do
    fn -> make_concurrent_requests(verb, url, concurrent_workers) end |>
      Stream.repeatedly |> Enum.take(n)
  end

  def make_concurrent_requests(verb, url, number_of_workers) do
    start_http_server
    workers = spawn_workers(number_of_workers)
    Enum.each workers, fn worker -> run_requests(worker, verb, url) end
    collect_responses(number_of_workers, [])
  end

  def run_requests(worker_id, verb, url) do
    worker_id <- { :request, self, verb, url }
  end

  def spawn_workers(number_of_workers) do
    fn -> spawn_link &worker/0 end |> Stream.repeatedly |> Enum.take(number_of_workers)
  end

  def start_http_server do
    :inets.start
  end

  defp worker do
    receive do
      { :request, parent_pid, verb, url } ->
        { time, { status, content } } = :timer.tc fn -> do_request(verb, url) end
        IO.inspect "Running Request"
        parent_pid <- { :response, {time/1000, status}, content }
        worker
      { :die } ->
        :ok
    end
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

  defp write_content_to_file(_content) do
  end
end

