defmodule Dobar.Intent.Evaluator.Wit do
  @moduledoc """
    This module has to communicate with the expression api provided by wit.ai
    It has to provide 2 basic functions: `text_query` and `voice_query`.
  """

  alias HTTPoison.Response

  def text_query(message, options \\ %{}) do
    case prepare_request(message, options) do
      {:ok, request} ->
        HTTPoison.get(request[:url], request[:headers])
        |> handle_response
        |> parse_response

      {:error, message} ->
        IO.puts "hell neaaaah"
        {:error, message}

      _ ->
        IO.puts "hell nowaaah"
        {:error, "unknown something-something broke"}
    end
    # {url, headers} = prepare_request message, options
    # HTTPoison.get(url, headers)
    # |> handle_response
    # |> parse_response
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

  # defp prepare_request(message) when is_bitstring message do
  #   url = "https://api.wit.ai/message?v=20141022&q=#{URI.encode message}"
  #   config = Application.get_env(:dobar, Intent.Evaluator)
  #   headers = %{"Authorization" => "Bearer #{config[:wit_token]}"}
  #   {url, headers}
  # end

  defp prepare_request(message, options) when is_bitstring message do
    context = case Map.keys(options) do
      [h | t] -> "&context=#{URI.encode(Poison.encode options)}"
      _ -> ""
    end
    URI.encode(message) <> context |> build_request
  end

  defp prepare_request(_, _), do: {:error, "the message must be a string"}

  defp build_request(message) do
    IO.puts "message: #{inspect message}"
    # url = "https://api.wit.ai/message?v=20141022&q=#{URI.encode message}"
    url = "https://api.wit.ai/message?v=20141022&q=#{message}"
    config = Application.get_env(:dobar, Intent.Evaluator)
    headers = %{"Authorization" => "Bearer #{config[:wit_token]}"}
    # {:ok, url, headers}
    {:ok, %{url: url, headers: headers}}
  end
end
