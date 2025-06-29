defmodule MedChat.Repo.Migrations.CreateSessions do
  use Ecto.Migration

  def change do
    create table(:sessions) do
      add :status, :integer
      add :patient_user_id, references(:users, on_delete: :nothing), null: false
      add :employee_user_id, references(:users, on_delete: :nothing)
      add :closed_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create index(:sessions, [:patient_user_id])
    create index(:sessions, [:employee_user_id])
  end
end
