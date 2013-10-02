defmodule Collector do
  def collect_responses(response_count, responses, parent_pid) when response_count == 0 do
    parent_pid <- { :responses, responses }
  end
  def collect_responses(response_count, responses, parent_pid) do
    receive do
      { :response, response_info, response_content } ->
        write_content_to_file(response_content)
        collect_responses(response_count - 1, [response_info]++responses, parent_pid)
    end
  end

  defp write_content_to_file(content) do
    content
  end
end
