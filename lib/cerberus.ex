defmodule Cerberus do
  def run(n // 1000, verb, url, concurrent_workers // 2) when concurrent_workers <= n do
    start_http_server
    worker_pool = spawn_collector(n, self) |> spawn_workers(concurrent_workers)
    do_run(n, verb, url, worker_pool)
  end
  def run(n, _verb, _url, concurrent_workers) when concurrent_workers > n do
    { :error, "Must have less workers than number of requests" }
  end

  defp do_run(n, _verb, _url, _worker_pool) when n <= 0 do
    receive do
      { :responses, responses } -> responses
    end
  end
  defp do_run(n, verb, url, worker_pool) do
    make_concurrent_requests(verb, url, worker_pool)
    do_run(n - Enum.count(worker_pool), verb, url, worker_pool)
  end

  defp spawn_collector(number_of_responses, parent_pid) do
    spawn_link fn -> Collector.collect_responses(number_of_responses, [], parent_pid) end
  end

  defp make_concurrent_requests(verb, url, workers) do
    Enum.each workers, fn(worker_id) -> run_requests(worker_id, verb, url) end
  end

  defp run_requests(worker_id, verb, url) do
    worker_id <- { :request, verb, url }
  end

  defp spawn_workers(collector_id, number_of_workers) do
    worker_fun = fn -> Worker.worker(collector_id) end
    fn -> spawn_link(worker_fun) end |> Stream.repeatedly |> Enum.take(number_of_workers)
  end

  defp start_http_server do
    :inets.start
  end
end
