defmodule DiscordBot.LMStudioLLM do
  @moduledoc """
  Module for interacting with a local LM Studio API to generate responses using LLMs.
  """

  require Logger

  @lm_studio_api "http://localhost:1234/v1/chat/completions"
  @system_prompt "You're a helpful assistant."
  @model "YOUR-MODEL-NAME-HERE"
  @max_tokens -1
  @temperature 0.7
  @timeout 300_000

  @doc """
  Sends a prompt to LM Studio and returns the generated response.

  ## Parameters
    - prompt: String containing the user's prompt

  ## Returns
    - {:ok, response} on success
    - {:error, reason} on failure
  """
  def query_lm_studio(prompt) do
    payload = %{
      model: @model,
      messages: [
        %{role: "system", content: @system_prompt},
        %{role: "user", content: prompt}
      ],
      temperature: @temperature,
      max_tokens: @max_tokens,
      stream: false
    }

    headers = [{"Content-Type", "application/json"}]
    options = [timeout: @timeout, recv_timeout: @timeout]

    with {:ok, response} <- make_request(@lm_studio_api, payload, headers, options),
         {:ok, content} <- extract_content(response.body) do
      {:ok, content}
    else
      {:error, {:http_error, status_code}} ->
        {:error, "The API returned an error (status code: #{status_code})."}

      error ->
        Logger.error("Unexpected error: #{inspect(error)}")
        {:error, "An unexpected error occurred. Check the logs for details."}
    end
  end

  defp make_request(url, payload, headers, options) do
    case HTTPoison.post(url, JSON.encode!(payload), headers, options) do
      {:ok, %HTTPoison.Response{status_code: 200} = response} ->
        {:ok, response}

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, {:http_error, status_code}}

      {:error, reason} ->
        Logger.error("HTTPoison error: #{inspect(reason)}")
        {:error, :generic}
    end
  end

  defp extract_content(body) do
    with {:ok, decoded_body} <- JSON.decode(body),
         {:ok, choices} <- get_choices(decoded_body),
         {:ok, content} <- get_content(choices) do
      {:ok, content}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_choices(decoded_body) do
    case Map.get(decoded_body, "choices") do
      nil -> {:error, "No choices found in response"}
      choices -> {:ok, choices}
    end
  end

  defp get_content(choices) do
    case Enum.at(choices, 0) do
      nil -> {:error, "No choices found in response"}
      %{"message" => %{"content" => content}} -> {:ok, content}
      %{"message" => _} -> {:error, "Content not found in response"}
      _ -> {:error, "Invalid choice structure"}
    end
  end
end
