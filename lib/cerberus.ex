defmodule Cerberus do

  def calculate_results(raw_results) do
    flattened_results = List.flatten(raw_results)
    average_response_time = calculate_avg_response_time flattened_results
    response_codes = calculate_response_codes flattened_results
    { average_response_time, response_codes }
  end

  defp calculate_avg_response_time(results) do
    IO.inspect results
    reducer = fn (result, acc) ->
      { time, _response_code } = result
      acc + time
    end
    Enum.reduce(results, 0, reducer) / Enum.count(results)
  end

  def calculate_response_codes(results) do
    all_codes = Enum.map results, fn result ->
      { _time, response_code } = result
      response_code
    end
    uniq_codes = Enum.uniq all_codes
    Enum.map uniq_codes, fn code ->
      { code, Enum.count(all_codes, fn c -> c == code end) }
    end
  end

  def run(n // 1000, verb, url, concurrent_workers // 2) when concurrent_workers <= n do
    start_http_server
    do_run(n, verb, url, concurrent_workers, [])
  end
  def run(n, _verb, _url, concurrent_workers) when concurrent_workers > n do
    IO.puts "Must have less workers than number of requests"
    []
  end

  def do_run(0, _verb, _url, _concurrent_workers, acc) do
    acc
  end
  def do_run(n, verb, url, concurrent_workers, acc) do
    IO.puts "Spawning"
    pool = spawn_workers(concurrent_workers)
    IO.puts "Spawning done"
    busy_workers = make_concurrent_requests(verb, url, pool, [])
    responses = List.flatten collect_responses(busy_workers, [])
    do_run(n - Enum.count(responses), verb, url, concurrent_workers, [responses|acc])
  end

  def make_concurrent_requests(_verb, _url, [], busy) do
    busy
  end
  def make_concurrent_requests(verb, url, [worker|rest], busy) do
    run_requests(worker, verb, url)
    make_concurrent_requests(verb, url, rest, [worker|busy])
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
        parent_pid <- { :response, self, {time/1000, status}, content }
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

  defp collect_responses([], responses) do
    responses
  end
  defp collect_responses([busy_worker|rest], responses) do
    receive do
      { :response, ^busy_worker, status, content } ->
        write_content_to_file(content)
        collect_responses(rest, [status|responses])
    end
  end

  defp write_content_to_file(_content) do
  end
end

