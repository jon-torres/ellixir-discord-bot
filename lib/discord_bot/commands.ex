defmodule DiscordBot.Commands do
  @moduledoc """
  This module defines the commands for the Discord bot. It contains functions that handle various commands issued by users in a Discord server.
  """

  alias Nostrum.Api.Message
  alias Nostrum.Api.Channel
  alias DiscordBot.OllamaLLM
  alias DiscordBot.LMStudioLLM
  require Logger

  def handle_command(msg) do
    llm_choice = Application.get_env(:discord_bot, :llm_choice, :lm_studio)

    case String.split(msg.content, " ", parts: 2) do
      ["!chatwithme", user_prompt] ->
        handle_llm_command(llm_choice, msg, user_prompt)

      ["!ping"] ->
        handle_ping_command(msg)

      ["!hello"] ->
        handle_hello_command(msg)

      ["!bypass", url] ->
        handle_bypass_command(msg, url)

      ["!help"] ->
        send_help_message(msg.channel_id)

      _ ->
        :ignore
    end
  end

  defp handle_llm_command(llm_choice, msg, user_prompt) do
    response =
      case llm_choice do
        :ollama ->
          OllamaLLM.query_ollama(user_prompt)

        :lm_studio ->
          LMStudioLLM.query_lm_studio(user_prompt)

        other ->
          Logger.error("Invalid LLM choice: #{other}")
          {:error, "Invalid LLM configuration. Check your settings."}
      end

    handle_llm_response(response, msg)
  end

  defp handle_llm_response({:ok, response_text}, msg) do
    Task.Supervisor.start_child(DiscordBot.TaskSupervisor, fn ->
      Channel.start_typing(msg.channel_id)

      Message.create(msg.channel_id,
        content: response_text,
        message_reference: %{message_id: msg.id}
      )
    end)

    :ok
  end

  defp handle_llm_response({:error, error_message}, msg) do
    Task.Supervisor.start_child(DiscordBot.TaskSupervisor, fn ->
      Message.create(msg.channel_id,
        content: error_message,
        message_reference: %{message_id: msg.id}
      )
    end)

    :ok
  end

  defp handle_ping_command(msg) do
    Task.Supervisor.start_child(DiscordBot.TaskSupervisor, fn ->
      Channel.start_typing(msg.channel_id)
      Message.create(msg.channel_id, "Huh... 'pong!', very funny.")
    end)

    :ok
  end

  defp handle_hello_command(msg) do
    Task.Supervisor.start_child(DiscordBot.TaskSupervisor, fn ->
      Channel.start_typing(msg.channel_id)
      Message.create(msg.channel_id, "Hello, #{msg.author.username}!")
    end)

    :ok
  end

  defp handle_bypass_command(msg, url) do
    Task.Supervisor.start_child(DiscordBot.TaskSupervisor, fn ->
      Channel.start_typing(msg.channel_id)
      Message.create(msg.channel_id, bypass_paywall(url))
    end)

    :ok
  end

  defp bypass_paywall(url) do
    cache_url = "https://removepaywalls.com/#{url}"
    cache_url
  end

  defp send_help_message(channel_id) do
    Channel.start_typing(channel_id)

    help_text = """
    **Bot Commands:**
    - `!chatwithme <message>` - Chat with the bot using LLM.
    - `!ping` - Responds with 'pong!'.
    - `!bypass <url>` - Attempts to bypass paywalls using removepaywalls.com.
    - `!help` - Shows this help message.
    """

    Message.create(channel_id, content: help_text)
  end
end
