defmodule MedChat.Repo.Migrations.CreateChatAssignments do
  use Ecto.Migration

  def change do
    create table(:chat_assignments) do
      add :assigned_at, :utc_datetime
      add :unassigned_at, :utc_datetime
      add :chat_session_id, references(:chat_sessions, on_delete: :nothing), null: false
      add :employee_id, references(:users, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:chat_assignments, [:chat_session_id])
    create index(:chat_assignments, [:employee_id])
  end
end
