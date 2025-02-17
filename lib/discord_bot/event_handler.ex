defmodule DiscordBot.EventHandler do
  @moduledoc """
  Handles Discord events, such as messages, reactions, and interactions.
  """

  use Nostrum.Consumer

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    if msg.author.bot do
      :ignore
    else
      Task.start(fn -> process_message(msg) end)
      Task.start(fn -> DiscordBot.Commands.handle_command(msg) end)
    end
  end

  def handle_event(_), do: :ignore

  def process_message(msg) do
    content = msg.content

    cond do
      contains_any_link?(content) ->
        DiscordBot.Webhooks.replace_and_send(msg)

      true ->
        :ignore
    end
  end

  defp contains_any_link?(content) do
    Enum.find_value(DiscordBot.Webhooks.link_patterns(), fn {old_domain, _} ->
      String.contains?(content, old_domain) && true
    end) || false
  end
end
