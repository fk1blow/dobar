defmodule Dobar.Conversation do
  @moduledoc """
  API entrypoint module for Dobar Conversation application.

  It represents the front API of Dobar's application, which is supposed to react
  to text and audio inputs; another type of input may be "data", which is usually
  results coming from 3p services(Dobar Interposer).
  The reaction of a conversation are always reactions that wrap either text or
  data. The data is to be sent to a 3p service!

  ## interface

  react(atom, String.t) :: :ok

  ## usage
  Use Conversation.react/1 when receiving input from the user, where the parameter
  is the raw input. The result is :ok because the conversation needs to be async
  when processing this data - mostly calls external "3p" apis.
  """

  use GenServer

  @conversation __MODULE__

  alias Dobar.Interface.Controller, as: InterfaceController

  def start_link do
    GenServer.start_link @conversation, [], name: @conversation
  end

  def init(_) do
    start_dialog_handlers
    {:ok, nil}
  end

  def react(:text, input),
    do: GenServer.cast @conversation, {:parse_input, :text, input}
  def react(:audio, input),
    do: GenServer.cast @conversation, {:parse_input, :audio, input}

  # callbacks
  #

  def handle_cast({:parse_input, :text, input}, _) do
    InterfaceController.parse_input {:text, input}
    {:noreply, nil}
  end
  def handle_cast({:parse_input, :audio, input}, _) do
    InterfaceController.parse_input {:audio, input}
    {:noreply, nil}
  end

  def handle_info({:gen_event_EXIT, _handler, _reason}, _manager) do
    start_dialog_handlers
    {:ok, nil}
  end

  defp start_dialog_handlers do
    GenEvent.add_mon_handler(:dialog_events, Dobar.Dialog.ReactionsHandler, nil)
    GenEvent.add_mon_handler(:dialog_events, Dobar.Dialog.InputHandler, nil)
  end
end
