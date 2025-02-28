defmodule DiscordBot.OllamaLLM do
  @moduledoc """
  This module handles interactions with the Ollama language model, providing a function to query the model with a given prompt.
  """
  @ollama_model "YOUR-MODEL-NAME-HERE"

  @doc """
  Sends a prompt to the Ollama language model and returns the generated response.

  ## Parameters
    - prompt: String containing the user's prompt

  ## Returns
    - {:ok, response} on success
    - {:error, reason} on failure
  """
  def query_ollama(prompt) do
    client = Ollama.init()

    case Ollama.completion(client,
           model: @ollama_model,
           prompt: prompt
         ) do
      {:ok, %{"response" => text}} ->
        {:ok, text}

      {:ok, unexpected_response} ->
        {:error, "Unexpected response format: #{inspect(unexpected_response)}"}

      {:error, reason} ->
        {:error, "Error communicating with Ollama: #{inspect(reason)}"}
    end
  end
end
