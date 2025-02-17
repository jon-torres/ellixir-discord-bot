defmodule DiscordBot.EventHandler do
  @moduledoc """
  Handles Discord events, such as messages, reactions, and interactions.
  """

  use Nostrum.Consumer

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    unless msg.author.bot do
      Task.Supervisor.start_child(DiscordBot.TaskSupervisor, fn -> process_message(msg) end)

      Task.Supervisor.start_child(DiscordBot.TaskSupervisor, fn ->
        DiscordBot.Commands.handle_command(msg)
      end)
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
    Enum.any?(DiscordBot.Webhooks.link_patterns(), fn {old_domain, _} ->
      String.contains?(content, old_domain)
    end)
  end
end
