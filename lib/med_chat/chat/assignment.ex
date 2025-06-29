defmodule MedChat.Chat.Assignment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "assignments" do
    field :assigned_at, :utc_datetime_usec
    field :unassigned_at, :utc_datetime_usec

    belongs_to :session, MedChat.Chat.Session
    belongs_to :user, MedChat.Account.User

    timestamps(type: :utc_datetime_usec)
  end

  def creation_changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:session_id, :user_id, :assigned_at])
    |> validate_required([:session_id, :user_id, :assigned_at])
    |> foreign_key_constraint(:session_id)
    |> foreign_key_constraint(:user_id)
  end

  def unassigned_changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:unassigned_at])
    |> validate_required([:unassigned_at])
  end
end
