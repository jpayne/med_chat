defmodule MedChat.Chat.Assignment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chat_assignments" do
    field :assigned_at, :utc_datetime
    field :unassigned_at, :utc_datetime

    belongs_to :chat_session, MedChat.Chat.Session
    belongs_to :employee, MedChat.Account.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:assigned_at, :unassigned_at])
    |> validate_required([:assigned_at, :unassigned_at])
  end
end
