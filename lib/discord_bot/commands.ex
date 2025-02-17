defmodule DiscordBot.Commands do
  @moduledoc """
  This module defines the commands for the Discord bot. It contains functions that handle various commands issued by users in a Discord server.
  """
  @ollama_model "YOUR-MODEL-NAME-HERE"
  alias Nostrum.Api.Message

  def handle_command(msg) do
    case String.split(msg.content, " ", parts: 2) do
      ["!bypass", url] -> Message.create(msg.channel_id, bypass_paywall(url))
      ["!chatwithme", user_prompt] -> query_ollama(user_prompt, msg)
      ["!help"] -> send_help_message(msg.channel_id)
      ["!ping"] -> Message.create(msg.channel_id, "Huh... 'pong!'. Very funny.")
      _ -> :ignore
    end
  end

  defp query_ollama(prompt, msg) do
    client = Ollama.init()

    case Ollama.completion(client,
           model: @ollama_model,
           prompt: prompt
         ) do
      {:ok, %{"response" => text}} ->
        Message.create(msg.channel_id,
          content: text,
          message_reference: %{message_id: msg.id}
        )

      {:ok, unexpected_response} ->
        Message.create(msg.channel_id,
          content: "Unexpected response format: #{inspect(unexpected_response)}",
          message_reference: %{message_id: msg.id}
        )

      {:error, reason} ->
        Message.create(msg.channel_id,
          content: "Error communicating with Ollama: #{inspect(reason)}",
          message_reference: %{message_id: msg.id}
        )
    end
  end

  defp bypass_paywall(url) do
    cache_url = "https://removepaywalls.com/#{url}"
    cache_url
  end

  defp send_help_message(channel_id) do
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
