defmodule MedChat.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :type, Ecto.Enum, values: [text: 1, system: 2]
    field :content, :string

    belongs_to :session, MedChat.Chat.Session
    belongs_to :user, MedChat.Account.User

    timestamps(type: :utc_datetime_usec)
  end

  defimpl Jason.Encoder, for: MedChat.Chat.Message do
    def encode(msg, opts) do
      %{
        message_id: msg.id,
        session_id: msg.session_id,
        user_id: msg.user_id,
        content: msg.content,
        timestamp: msg.inserted_at
      }
      |> Jason.Encode.map(opts)
    end
  end

  def creation_changeset(message, attrs) do
    message
    |> cast(attrs, [:session_id, :user_id, :content])
    |> put_change(:type, :text)
    |> validate_required([:session_id, :user_id, :content, :type])
    |> foreign_key_constraint(:session_id)
    |> foreign_key_constraint(:user_id)
  end

  def system_changeset(message, attrs) do
    message
    |> cast(attrs, [:session_id, :content])
    |> put_change(:type, :system)
    |> validate_required([:session_id, :type, :content])
    |> foreign_key_constraint(:session_id)
  end
end
