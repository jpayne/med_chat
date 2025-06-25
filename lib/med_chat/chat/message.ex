defmodule MedChat.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chat_messages" do
    field :type, :string
    field :content, :string

    belongs_to :chat_session, MedChat.Chat.Session
    belongs_to :user, MedChat.Account.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:type, :content])
    |> validate_required([:type, :content])
  end
end
