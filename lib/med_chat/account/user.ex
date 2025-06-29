defmodule MedChat.Account.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    # All users
    field :name, :string
    field :email, :string

    # Employee-specific
    field :is_employee, :boolean, default: false
    field :status, Ecto.Enum, values: [unavailable: 1, waiting: 2, assigned: 3]
    field :last_assignment_at, :utc_datetime_usec

    has_many :chat_messages, MedChat.Chat.Message, foreign_key: :user_id
    has_many :patient_chat_sessions, MedChat.Chat.Session, foreign_key: :patient_user_id
    has_many :employee_chat_sessions, MedChat.Chat.Session, foreign_key: :employee_user_id
    has_many :chat_assignments, MedChat.Chat.Assignment, foreign_key: :user_id

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :is_employee, :status])
    |> validate_required([:email, :name, :is_employee, :status])
  end

  def availability_changeset(user, attrs) do
    user
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end

  def assignment_changeset(user, attrs) do
    user
    |> cast(attrs, [:status, :last_assignment_at])
    |> validate_required([:status, :last_assignment_at])
  end
end
