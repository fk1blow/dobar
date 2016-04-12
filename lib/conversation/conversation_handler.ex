defmodule Dobar.Conversation.ConversationHandler do
  require Logger

  use GenEvent

  def handle_event({:conversation_reply, reply}, nil) do
    Logger.info "should reply to the user with #{inspect reply}"
    {:ok, nil}
  end

  def handle_event({:intention_unconfident, intent}, _) do
    Logger.info "intention confidence to low: #{inspect intent}"
    {:ok, nil}
  end

  def handle_event({:conversation_end, reply, intent}, _) do
    Logger.info "the intention has finished: #{inspect reply} with intent: #{inspect intent}"
    {:ok, nil}
  end

  def handle_event({:conversation_cancel, _}, _) do
    Logger.info "conversation has been canceled"
    {:ok, nil}
  end

  def handle_event({:conversation_halt, reason}, _) do
    Logger.info "intention halted for whatever reason: #{inspect reason}"
    {:ok, nil}
  end

  def handle_event({:conversation_error, reason}, _) do
    Logger.info "there has been an error when trying to process intention"
    {:ok, nil}
  end

  def handle_event({:conversation_start, intent}, _) do
    Logger.info "a new conversation has started: #{inspect intent}"
    {:ok, nil}
  end
end
