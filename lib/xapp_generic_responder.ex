defmodule Dobar.Xapp.GenericResponder do
  use Dobar.Responder

  alias HTTPoison.Response
  alias HTTPoison.Error
  alias Dobar.Reaction
  alias Dobar.EvaluationError

  @default_where "Bucharest"
  @location_api "http://maps.googleapis.com/maps/api/geocode/json?sensor=false"
  @timezone_api "http://api.timezonedb.com/v2/get-time-zone?key=MWTIKWN1FRYX&by=position&format=json"

  on %EvaluationError{} = error do
    reply interface, {:text, "sorry but i was unable to process your input"}
    reply interface, {:text, "please try again"}
  end

  on %Reaction{about: :question} = reaction do
    reply interface, {:text, reaction.text}
  end

  on %Reaction{about: :canceled} do
    reply interface, {:text, "oookay, i'm canceling it!"}
  end

  on %Reaction{about: :no_alternative_found} do
    reply interface, {:text, "Sorry, i didn't get that"}
  end

  on %Reaction{about: :low_confidence_intent} do
    reply interface, {:text, "Sorry, i didn't get that"}
  end

  on %Reaction{about: :undefined_intention} do
    reply interface, {:text, "Sorry, i didn't get that"}
  end

  on %Reaction{about: :meta_as_root} do
    reply interface, {:text, "Sorry, i didn't get that"}
  end

  on %Reaction{about: :purge_nomatches} = reaction do
    reply interface, {:text, "cannot change the fields because some are unavailable"}
  end

  on %Reaction{trigger: %{name: "say_time"}, features: %{where: %{value: nil}}} do
    display_time(interface, @default_where)
  end

  on %Reaction{trigger: %{name: "say_time"}, features: %{where: %{value: [head | _] = cities}}} do
    # should actually get the time for each of the cities in the `value` but for
    # the time being, take just the first
    display_time(interface, head)
  end

  defp display_time(interface, location) do
    location
    |> fetch_location
    |> process_response
    |> get_location
    |> fetch_timezone
    |> process_response
    |> get_timezone
    |> (&(reply(interface, {:text, &1}))).()
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
    HTTPoison.get(@location_api <> "&address=#{URI.encode address}")
  end

  defp fetch_timezone(%{"lat" => lat, "lng" => lng}) do
    HTTPoison.get(@timezone_api <> "&lat=#{lat}&lng=#{lng}")
  end
end
