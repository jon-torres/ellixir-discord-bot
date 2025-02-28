import Config

config :nostrum,
  token: System.get_env("DISCORD_TOKEN"),
  gateway_intents: :all,
  ffmpeg: nil,
  log_ratelimits: :warn

config :discord_bot, :llm_choice, String.to_atom(System.get_env("LLM_CHOICE", "lm_studio"))
