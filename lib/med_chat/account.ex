defmodule MedChat.Account do
  import Ecto.Query
  alias MedChat.Repo
  alias MedChat.Account.User
  alias MedChat.Chat.Session

  def get_user(user_id), do: Repo.get(User, user_id)

  def get_user!(user_id), do: Repo.get!(User, user_id)

  def get_employee(user_id), do: Repo.get_by(User, id: user_id, is_employee: true)

  def get_employee!(user_id), do: Repo.get_by!(User, id: user_id, is_employee: true)

  # Convenience functions for testing
  def fetch_employee(user_id) do
    from(User, where: [id: ^user_id, is_employee: true])
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      employee -> {:ok, employee}
    end
  end

  def fetch_patient do
    from(User, where: [is_employee: false])
    |> first()
    |> Repo.one()
  end

  def get_employee_if_available(user_id) do
    from(User,
      where: [id: ^user_id, is_employee: true, status: :waiting]
    )
    |> Repo.one()
  end

  def get_available_employee do
    case get_available_employees() do
      [employee | _] -> employee
      [] -> nil
    end
  end

  # It might not be true, but let's assume for now that
  # employees can only be assigned to one active chat at a time:
  def get_available_employees do
    from(u in User,
      left_join: s in Session,
      on: u.id == s.employee_user_id and s.status == :active,
      where: u.is_employee == true and u.status == :waiting and is_nil(s.employee_user_id),
      order_by: [asc: u.last_assignment_at] # Order by oldest assignment
    )
    |> Repo.all()
  end

  def update_employee_status(%User{is_employee: true} = user, status) do
    user
    |> User.availability_changeset(%{status: status})
    |> Repo.update()
  end
end
