defmodule MedChat.Repo.Migrations.CreateChatMessages do
  use Ecto.Migration

  def change do
    create table(:chat_messages) do
      add :type, :integer # Ecto.Enum, values: [text: 1, system: 2]
      add :content, :text
      add :chat_session_id, references(:chat_sessions, on_delete: :nothing), null: false
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:chat_messages, [:chat_session_id])
    create index(:chat_messages, [:user_id])
  end
end
