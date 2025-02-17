defmodule DiscordBot.Webhooks do
  @moduledoc """
  Handles replacing links and sending messages via Discord webhooks.
  """

  require Logger

  @link_patterns %{
    "instagram.com" => "ddinstagram.com",
    "reddit.com" => "vxreddit.com",
    "tiktok.com" => "vxtiktok.com",
    "twitter.com" => "vxtwitter.com",
    "x.com" => "vxtwitter.com"
  }

  def link_patterns, do: @link_patterns

  @doc """
  Detects and replaces URLs in a message. Then, sends a webhook message and deletes the original.
  """
  @spec replace_and_send(any()) :: :ok | {:ok, pid()}
  def replace_and_send(msg) do
    updated_content = replace_links(msg.content)

    with {:ok, webhook} <- get_or_create_webhook(msg.channel_id, msg.author),
         :ok <- send_webhook_message(webhook, msg.author, updated_content) do
      Task.start(fn -> delayed_message_deletion(msg) end)
    else
      {:error, reason} -> Logger.error("Error: #{inspect(reason)}")
    end
  end

  defp replace_links(content) do
    Logger.info("Replacing links in: #{content}")

    Enum.reduce(@link_patterns, content, fn {old, new}, acc ->
      String.replace(acc, old, new)
    end)
  end

  defp get_or_create_webhook(channel_id, author) do
    case Nostrum.Api.Channel.webhooks(channel_id) do
      {:ok, webhooks} ->
        case Enum.find(webhooks, &(&1.name == author.username)) do
          nil -> create_webhook(channel_id, author)
          webhook -> {:ok, webhook}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp create_webhook(channel_id, author) do
    case Nostrum.Api.Webhook.create(channel_id, author.username, "") do
      {:ok, webhook} ->
        {:ok, webhook}

      {:error, reason} ->
        Logger.error("Failed to create webhook: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp send_webhook_message(webhook, author, content) do
    webhook_url = "https://discord.com/api/webhooks/#{webhook.id}/#{webhook.token}"

    payload = %{
      "content" => content,
      "username" => author.username,
      "avatar_url" => "https://cdn.discordapp.com/avatars/#{author.id}/#{author.avatar}.png"
    }

    case HTTPoison.post(webhook_url, Jason.encode!(payload), [
           {"Content-Type", "application/json"}
         ]) do
      {:ok, %HTTPoison.Response{status_code: 204}} ->
        :ok

      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        Logger.error("Unexpected response: Status #{status}, Body: #{body}")
        {:error, :unexpected_response}

      {:error, reason} ->
        Logger.error("HTTP request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp delayed_message_deletion(msg) do
    Process.sleep(500)

    case Nostrum.Api.Message.delete(msg.channel_id, msg.id) do
      {:ok} -> Logger.info("Deleted message: #{msg.id}")
      other -> Logger.error("Failed to delete message: #{inspect(other)}")
    end
  end
end
