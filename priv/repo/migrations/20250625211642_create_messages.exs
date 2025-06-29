defmodule MedChat.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :type, :integer
      add :content, :text
      add :session_id, references(:sessions, on_delete: :nothing), null: false
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime_usec)
    end

    create index(:messages, [:session_id])
    create index(:messages, [:user_id])
  end
end
