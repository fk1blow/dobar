defmodule Dobar.Spub.OutputHandler do
  @moduledoc """
  Has the responsability to handle events and notifications related to the output
  that will reach the ui/user.
  """

  require Logger

  use GenEvent

  alias Dobar.Model.Response

  def handle_event({:response_evaluated, %Response{} = response}, _state) do
    Logger.info "response was evaluated to: #{inspect response}"
    Dobar.Interface.Controller.parse_output response
    {:ok, nil}
  end
end
