defmodule MedChat.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :name, :string, null: false
      add :is_employee, :boolean, null: false, default: false
      add :status, :integer
      add :last_assignment_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:users, [:email])
    create index(:users, [:is_employee, :status])
  end
end
