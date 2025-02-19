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
  def replace_and_send(msg) do
    updated_content = replace_links(msg.content)
    display_name = get_display_name(msg)

    with {:ok, webhook} <- get_or_create_webhook(msg.channel_id, display_name, msg.author),
         :ok <- send_webhook_message(webhook, display_name, msg.author, updated_content) do
      Task.Supervisor.start_child(DiscordBot.TaskSupervisor, fn ->
        delayed_message_deletion(msg)
      end)
    else
      {:error, reason} -> Logger.error("Error: #{inspect(reason)}")
    end
  end

  defp replace_links(content) do
    Logger.info("Replacing links in: #{content}")

    Enum.reduce(@link_patterns, content, fn {old, new}, acc ->
      Regex.replace(~r/\b#{Regex.escape(old)}\b/, acc, new)
    end)
  end

  defp get_display_name(%{member: %{nick: nick}}) when not is_nil(nick), do: nick
  defp get_display_name(%{author: %{username: username}}), do: username

  defp get_or_create_webhook(channel_id, display_name, author) do
    with {:ok, webhooks} <- Nostrum.Api.Channel.webhooks(channel_id),
         nil <- Enum.find(webhooks, &(&1.name == display_name)) do
      create_webhook(channel_id, display_name, author)
    else
      webhook when is_map(webhook) -> {:ok, webhook}
      error -> error
    end
  end

  defp create_webhook(channel_id, display_name, author) do
    base_payload = %{name: display_name}

    payload =
      if author.avatar do
        Map.put(base_payload, :avatar, author.avatar)
      else
        base_payload
      end

    Logger.debug("Sending webhook creation request: #{inspect(payload)}")

    case Nostrum.Api.Webhook.create(channel_id, payload) do
      {:ok, webhook} ->
        Logger.info("Webhook created successfully: #{inspect(webhook)}")
        {:ok, webhook}

      {:error, reason} ->
        Logger.error("Failed to create webhook: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp send_webhook_message(webhook, display_name, author, content) do
    webhook_url = "https://discord.com/api/webhooks/#{webhook.id}/#{webhook.token}"

    payload = %{
      "content" => content,
      "username" => display_name,
      "avatar_url" => "https://cdn.discordapp.com/avatars/#{author.id}/#{author.avatar}.png"
    }

    headers = [{"Content-Type", "application/json"}]

    case HTTPoison.post(webhook_url, JSON.encode!(payload), headers) do
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
