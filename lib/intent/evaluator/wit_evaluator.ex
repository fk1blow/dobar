defmodule Dobar.Intent.Evaluator.Wit do
  alias HTTPoison.Response

  def text_query(message) do
    {url, headers} = prepare_request message
    HTTPoison.get(url, headers)
    |> handle_response
    |> parse_response
  end

  def handle_response({:ok, %Response{status_code: 200, body: body}}) do
    {:ok, body}
  end

  def handle_response({:ok, %Response{body: body}}) do
    {:error, body}
  end

  def parse_response({:ok, body}) do
    case Poison.decode(body, keys: :atoms) do
      {:ok, value} -> {:ok, value}
      error -> {:error, "unable to parse wit response"}
    end
  end

  def parse_response({:error, body}) do
    {:error, body}
  end

  defp prepare_request(message) when is_bitstring message do
    url = "https://api.wit.ai/message?v=20141022&q=#{URI.encode message}"
    config = Application.get_env(:dobar, Intent.Evaluator)
    headers = %{"Authorization" => "Bearer #{config[:wit_token]}"}
    {url, headers}
  end
end
