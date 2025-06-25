defmodule MedChat.Chat.Session do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chat_sessions" do
    field :status, :string

    belongs_to :patient, MedChat.Account.User
    belongs_to :employee, MedChat.Account.User
    has_many :chat_messages, MedChat.Chat.Message, foreign_key: :chat_session_id
    has_many :chat_assignments, MedChat.Chat.Assignment, foreign_key: :chat_session_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(session, attrs) do
    session
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end
end
