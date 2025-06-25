defmodule MedChat.Repo do
  use Ecto.Repo,
    otp_app: :med_chat,
    adapter: Ecto.Adapters.Postgres
end
