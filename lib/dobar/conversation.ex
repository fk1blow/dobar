defmodule Dobar.Conversation do
  @moduledoc """
  API entrypoint module for Dobar Conversation application.

  It represents the front API of Dobar's application, which is supposed to react
  to text and audio inputs; another type of input may be "data", which is usually
  results coming from 3p services(Dobar Interposer).
  The reaction of a conversation are always reactions that wrap either text or
  data. The data is to be sent to a 3p service!

  ## interface

  Conversation.react/2

  @spec react(type :: atom, input :: String.t | AudioBuffer.t) :: :ok

  ## usage

  Use Conversation.react/1 when receiving input from the user, where the parameter
  is the raw input. The result is :ok because the conversation needs to be async
  when processing this data - mostly calls external "3p" apis.

  ## the need for a GenServer

  Basically, the need for a genserver is related to the GenEvent handler to
  `dialog_events` which sets up handlers to `ReactionHandler` and `InputHandler`.
  Also, this deals nicely with the supervision, where a handler dies and needs to
  be restarted - this server will deal with adding the handlers back to the manager.

  TODO: add input handler to the flow, however that will be
  """

  use GenServer
  # alias Dobar.Interface.Controller, as: InterfaceController

  @server __MODULE__
  @type conversation_input :: String.t | AudioBuffer.t

  def start_link(opts) do
    GenServer.start_link @server, opts, name: @server
  end

  def init(args) do
    state = %{input_events_manager: args[:input_events_manager],
              dialog_events_manager: args[:dialog_events_manager]}
    start_event_handlers(state)
    {:ok, state}
  end

  # ????????????????????????????????????????????????????????????
  # @spec react(type :: atom, input :: conversation_input) :: :ok
  # def react(:text, input),
  #   do: GenServer.cast @conversation, {:parse_input, :text, input}
  # def react(:audio, input),
  #   do: GenServer.cast @conversation, {:parse_input, :audio, input}

  # ????????????????????????????????????????????????????????????
  # def handle_cast({:parse_input, :text, input}, _) do
  #   InterfaceController.parse_input {:text, input}
  #   {:noreply, nil}
  # end
  # def handle_cast({:parse_input, :audio, input}, _) do
  #   InterfaceController.parse_input {:audio, input}
  #   {:noreply, nil}
  # end

  def handle_info({:gen_event_EXIT, _handler, _reason}, state) do
    start_event_handlers(state)
    {:ok, state}
  end

  defp start_event_handlers(event_managers) do
    GenEvent.add_mon_handler(
      event_managers[:input_events_manager], Dobar.Conversation.TextInputHandler, nil)

    GenEvent.add_mon_handler(
      event_managers[:dialog_events_manager], Dobar.Conversation.ReactionHandler, nil)

    # GenEvent.add_mon_handler(
    #   event_managers[:dialog_events], Dobar.Dialog.InputHandler, nil)
  end
end
