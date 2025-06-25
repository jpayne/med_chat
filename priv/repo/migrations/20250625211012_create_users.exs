defmodule MedChat.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :name, :string, null: false
      add :is_employee, :boolean, null: false, default: false
      add :is_available, :boolean, null: false, default: false

      timestamps(type: :utc_datetime)
    end
  end
end
