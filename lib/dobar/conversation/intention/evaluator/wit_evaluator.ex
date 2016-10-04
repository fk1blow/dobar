# TODO: should be moved outside the conversation/intention modules
defmodule Dobar.Conversation.Intention.Evaluator.Wit do
  @moduledoc """
  This module has to communicate with the expression api provided by wit.ai
  It has to provide 2 basic functions: `text_query` and `voice_query`.
  """

  alias HTTPoison.Response
  alias HTTPoison.Error

  @request_timeout 5000

  def text_query(message, conf) do
    case generate_request(message, conf) do
      {:ok, request} ->
        HTTPoison.get(request[:url], request[:headers], [timeout: @request_timeout])
        |> handle_response
        |> parse_response
      {:error, message} -> {:error, message}
    end
  end

  defp handle_response({:ok, %Response{status_code: 200, body: body}}) do
    {:ok, body}
  end
  defp handle_response({:error, %Error{reason: reason}}) do
    {:error, reason}
  end

  defp parse_response({:ok, body}) do
    case Poison.decode(body, keys: :atoms) do
      {:ok, value} -> {:ok, value}
      error -> {:error, "unable to parse wit response"}
    end
  end
  defp parse_response({:error, body}) do
    {:error, body}
  end

  defp generate_request(message, conf) when is_bitstring message do
    URI.encode(message) |> build_request(conf)
  end
  defp generate_request(_, _), do: {:error, "the message must be a string"}

  defp build_request(message, opts \\ []) do
    url = "https://api.wit.ai/message?v=20160516&q=#{message}"
    headers = %{"Authorization" => "Bearer #{opts[:token]}"}
    {:ok, %{url: url, headers: headers}}
  end
end
