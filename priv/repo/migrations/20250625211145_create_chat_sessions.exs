defmodule MedChat.Repo.Migrations.CreateChatSessions do
  use Ecto.Migration

  def change do
    create table(:chat_sessions) do
      add :status, :integer # Ecto.Enum, values: [waiting: 1, active: 2, closed: 3]
      add :patient_id, references(:users, on_delete: :nothing), null: false
      add :employee_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:chat_sessions, [:patient_id])
    create index(:chat_sessions, [:employee_id])
  end
end
