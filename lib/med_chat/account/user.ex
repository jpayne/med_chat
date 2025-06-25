defmodule MedChat.Account.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    field :is_employee, :boolean, default: false
    field :is_available, :boolean, default: false

    has_many :chat_messages, MedChat.Chat.Message, foreign_key: :user_id
    has_many :patient_chat_sessions, MedChat.Chat.Session, foreign_key: :patient_id
    has_many :employee_chat_sessions, MedChat.Chat.Session, foreign_key: :employee_id
    has_many :chat_assignments, MedChat.Chat.Assignment, foreign_key: :employee_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :is_employee, :is_available])
    |> validate_required([:email, :name, :is_employee, :is_available])
  end
end
