# eLLixir Discord Bot

I tried my best to come up with a name that mixes (no pun intended) "Elixir" and "LLM", hence "eLLixir".

## Introduction
I am currently learning Elixir, and as part of my learning journey, I decided to translate my Python Discord bot into Elixir. This bot is built using the `Nostrum` library for Discord interactions and features commands for interacting with an LLM, bypassing paywalls, and replacing links in messages. It's my first shot into getting elixir code ready for others to use, so I hope you like it. 

## Features
- Chat with an AI model using `!chatwithme <message>`.
- Bypass paywalls using `!bypass <url>`.
- Replace certain social media links in messages with alternative versions, making videos available in the chat.
- Webhook-based message modification and deletion.
- Uses `Task.Supervisor` for better concurrency and scalability.

## Why Elixir?
Elixir is an amazing functional programming language built on the Erlang VM, known for its fault tolerance, scalability, and concurrent processing. Here are some of the reasons I chose Elixir for this project:

1. **Concurrency**: The bot can handle multiple messages efficiently due to Elixir’s lightweight processes.
2. **Fault Tolerance**: The supervision tree allows for process recovery, making the bot more resilient.
3. **Functional Programming**: Encourages a declarative approach, making the code more predictable and maintainable.
4. **Scalability**: The bot can easily scale to handle a larger Discord server with minimal changes.
5. **Learning Experience**: As a Python developer, learning Elixir introduces new paradigms such as pattern matching and immutability.

## Modules
### `DiscordBot`
The main module that delegates command handling, message processing, and webhook-related functions.

### `DiscordBot.Commands`
Handles user-issued commands such as:
- `!bypass <url>` - Generates a bypass link.
- `!chatwithme <message>` - Sends a message to an AI model.
- `!help` - Displays available commands.
- `!ping` - Replies with 'pong!'.

### `DiscordBot.Webhooks`
Responsible for detecting and replacing specific links in messages before reposting them through webhooks.

### `DiscordBot.EventHandler`
Handles all incoming Discord messages and distributes them asynchronously using `Task.Supervisor` to prevent blocking.

## Dependencies
- [`Nostrum`](https://hex.pm/packages/nostrum) - A Discord API library for Elixir.
- [`HTTPoison`](https://hex.pm/packages/httpoison) - HTTP client for sending webhook messages.
- [`Jason`](https://hex.pm/packages/jason) - JSON parsing library.

## Setup & Running
1. Clone the repository:
   ```sh
   git clone git@github.com:jon-torres/ellixir.git
   cd ellixir
   ```
2. Install dependencies:
   ```sh
   mix deps.get
   ```
3. Set your Discord bot token in the environment variables.
4. Run the bot:
   ```sh
   iex -S mix
   ```
   or
   ```sh
   mix run --no-halt
   ```

## Future Improvements
- Implement database storage for user preferences.
- Improve error handling with better logging and retry mechanisms.
- Expand AI model interactions with agents.
- Improve tests.

## License
This project is licensed under the MIT License.
