defmodule Dobar.Xapp.GenericResponder do
  use Dobar.Responder

  alias HTTPoison.Response
  alias HTTPoison.Error

  @default_where "Bucharest"
  @location_api "http://maps.googleapis.com/maps/api/geocode/json?sensor=false"

  on :say_time, data: %{features: %{where: %{value: nil}}} do
    fetch_time(@default_where)
  end

  on :say_time, data: %{features: %{where: %{value: value}}} do
    fetch_time(value)
  end

  defp fetch_time(where) do
    where
    |> fetch_location
    |> process_response
    |> get_location
    |> fetch_timezone
    |> process_response
    |> get_timezone
    |> (&(IO.inspect &1)).()
  end

  defp fetch_url(url) do
    Stream.resource(
      fn -> HTTPoison.get(url) end,
      fn response -> process_response(response) end,
      fn _ -> end
    )
  end

  defp process_response({:ok, %Response{body: body}}) do
    {:ok, res} = Poison.Parser.parse(body)
    res
  end

  defp process_response({:error, %Error{reason: reason}}) do
    {:error, reason}
  end

  defp get_location(result) do
    result["results"] |> hd |> Map.get("geometry") |> Map.get("location")
  end

  defp get_timezone(%{"timestamp" => timestamp}) do
    timestamp |> DateTime.from_unix |> (&(elem(&1, 1))).() |> DateTime.to_string
  end

  defp fetch_location(address) do
    HTTPoison.get(@location_api <> "&address=#{address}")
  end

  defp fetch_timezone(%{"lat" => lat, "lng" => lng}) do
    url = "http://api.timezonedb.com/v2/get-time-zone?key=MWTIKWN1FRYX&by=position&format=json"
    HTTPoison.get(url <> "&lat=#{lat}&lng=#{lng}")
  end
end
