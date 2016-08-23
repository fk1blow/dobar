defmodule Dobar.Spub.InterfaceHandler do
  @moduledoc """
  Has the responsability to handle events and notifications related to the output
  that will reach the ui/user.
  """

  require Logger

  use GenEvent

  alias Dobar.Model.Response

  def handle_event({:response_evaluated, %Response{} = response}, _state) do
    Logger.info "response has been evaluated to: #{inspect response}"
    Dobar.Interface.Controller.send_output {:text, response}
    {:ok, nil}
  end
end
