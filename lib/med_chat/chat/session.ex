defmodule MedChat.Chat.Session do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sessions" do
    field :status, Ecto.Enum, values: [waiting: 1, active: 2, closed: 3]
    field :closed_at, :utc_datetime_usec

    belongs_to :patient, MedChat.Account.User, foreign_key: :patient_user_id
    belongs_to :employee, MedChat.Account.User, foreign_key: :employee_user_id
    has_many :messages, MedChat.Chat.Message, foreign_key: :session_id
    has_many :assignments, MedChat.Chat.Assignment, foreign_key: :session_id

    timestamps(type: :utc_datetime_usec)
  end

  def creation_changeset(session, attrs) do
    session
    |> cast(attrs, [:patient_user_id])
    |> put_change(:status, :waiting)
    |> validate_required([:patient_user_id, :status])
    |> foreign_key_constraint(:patient_user_id)
  end

  def status_changeset(session, attrs) do
    session
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end

  def assignment_changeset(session, attrs) do
    session
    |> cast(attrs, [:employee_user_id, :status])
    |> validate_required([:employee_user_id, :status])
    |> foreign_key_constraint(:employee_user_id)
  end
end
