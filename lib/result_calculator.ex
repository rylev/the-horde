defmodule ResultCalculator do
  def calculate_results(raw_results) do
    flattened_results = List.flatten(raw_results)
    average_response_time = calculate_avg_response_time flattened_results
    response_codes = calculate_response_codes flattened_results
    { average_response_time, response_codes }
  end

  defp calculate_avg_response_time(results) do
     total_reponse_time(results) / Enum.count(results)
  end

  def total_reponse_time(results) do
    reducer = fn (result, acc) ->
      { time, _response_code } = result
      acc + time
    end
    Enum.reduce(results, 0, reducer)
  end

  defp calculate_response_codes(results) do
    all_codes(results) |> Enum.uniq |> Enum.map fn code ->
      { code, Enum.count(all_codes(results), &(&1 == code)) }
    end
  end

  def all_codes(results) do
    Enum.map results, fn result ->
      { _time, response_code } = result
      response_code
    end
  end
end
