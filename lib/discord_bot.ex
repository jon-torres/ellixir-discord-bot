defmodule DiscordBot do
  @moduledoc """
  The main module for the Discord bot.
  """

  alias DiscordBot.Commands
  alias DiscordBot.Webhooks
  alias DiscordBot.EventHandler

  defdelegate handle_command(msg), to: Commands
  defdelegate process_message(msg), to: EventHandler
  defdelegate replace_and_send(msg), to: Webhooks
end
