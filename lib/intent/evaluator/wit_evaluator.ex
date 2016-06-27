defmodule Dobar.Intent.Evaluator.Wit do
  @moduledoc """
  This module has to communicate with the expression api provided by wit.ai
  It has to provide 2 basic functions: `text_query` and `voice_query`.
  """

  alias HTTPoison.Response

  def text_query(message, context) do
    case generate_request(message, context) do
      {:ok, request} ->
        IO.puts "request: #{inspect request}"
        HTTPoison.get(request[:url], request[:headers])
        |> handle_response
        |> parse_response

      {:error, message} -> {:error, message}
    end
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

  def generate_request(message, context) when is_bitstring message do
    URI.encode(message) |> build_request
  end
  def generate_request(_, _), do: {:error, "the message must be a string"}

  defp build_request(message) do
    url = "https://api.wit.ai/message?v=20160516&q=#{message}"
    IO.puts "wit q: #{message}"
    config = Application.get_env(:dobar, Intent.Evaluator)
    headers = %{"Authorization" => "Bearer #{config[:wit_token]}"}
    {:ok, %{url: url, headers: headers}}
  end
end
