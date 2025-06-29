defmodule MedChat.Repo.Migrations.CreateAssignments do
  use Ecto.Migration

  def change do
    create table(:assignments) do
      add :assigned_at, :utc_datetime_usec
      add :unassigned_at, :utc_datetime_usec
      add :session_id, references(:sessions, on_delete: :nothing), null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:assignments, [:session_id])
    create index(:assignments, [:user_id])
  end
end
