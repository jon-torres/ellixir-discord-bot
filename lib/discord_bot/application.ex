defmodule DiscordBot.Application do
  @moduledoc """
  The Application module is responsible for starting and supervising the bot's processes.
  """

  use Application

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: DiscordBot.TaskSupervisor},
      DiscordBot.EventHandler
    ]

    opts = [strategy: :one_for_one, name: DiscordBot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
