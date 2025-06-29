defmodule MedChat.Chat do
  import Ecto.Query
  alias Ecto.Multi
  alias Ecto.Changeset
  alias MedChat.Repo
  alias MedChat.Account
  alias MedChat.Account.User
  alias MedChat.Chat.{Assignment, Message, Session}
  alias Phoenix.PubSub

  def create_session(user_id) do
    user = Account.get_user!(user_id)
    %Session{}
    |> Session.creation_changeset(%{patient_user_id: user.id})
    |> Repo.insert()
    |> case do
      {:ok, session} ->
        session = Repo.preload(session, [:patient, :employee])
        find_available_employee_for_session(session)
        {:ok, session}

      error -> error
    end
  end

  def get_session!(session_id), do: Repo.get!(Session, session_id)

  def get_session_with_associations(session_id) do
    Session
    |> preload([messages: [:user], patient: [], employee: []])
    |> Repo.get(session_id)
  end

  def close_session(%Session{} = session, %User{} = user) do
    create_system_message(session, "#{user.name} left the chat. This session has ended.")
    session
    |> Changeset.change(%{status: :closed, closed_at: DateTime.utc_now()})
    |> Repo.update()
    |> case do
      {:ok, session} ->
        close_assignments(session)
        broadcast_session_update(session)
        {:ok, session}

      error -> error
    end
  end

  def create_message(%{session_id: session_id, user_id: user_id, content: content}) do
    session = get_session!(session_id)
    user = Account.get_user!(user_id)
    %Message{}
    |> Message.creation_changeset(%{
      session_id: session.id,
      user_id: user.id,
      content: content
    })
    |> Repo.insert()
    |> case do
      {:ok, message} ->
        message = Repo.preload(message, [:user, :session])
        broadcast_message(message)
        {:ok, message}
      error -> error
    end
  end

  def list_messages(session_id) do
    from(m in Message,
      where: m.session_id == ^session_id,
      order_by: [asc: m.inserted_at, asc: m.id],
      preload: [:user]
    ) |> Repo.all()
  end

  def create_assignment(session_id, user_id) do
    session = get_session!(session_id)
    case Account.get_employee_if_available(user_id) do
      %User{} = user ->
        assignment = %Assignment{}
        |> Assignment.creation_changeset(%{
          session_id: session.id,
          user_id: user.id,
          assigned_at: DateTime.utc_now()
        })
        |> Repo.insert!()
        |> Repo.preload([:user])
        {:ok, assignment}

      nil ->
        {:error, "employee is not available"}
    end
  end

  def list_assignments(session_id) do
    from(a in Assignment,
      where: a.session_id == ^session_id,
      order_by: [asc: a.assigned_at, asc: a.id]
    )
    |> Repo.all()
  end

  def make_employee_available(user_id) do
    employee = Account.get_employee!(user_id)
    Account.update_employee_status(employee, :waiting)
  end

  def make_employee_unavailable(user_id) do
    employee = Account.get_employee!(user_id)
    case Account.update_employee_status(employee, :unavailable) do
      {:ok, employee} ->
        active_sessions = get_active_employee_sessions(user_id)

        Enum.each(active_sessions, fn session ->
          create_system_message(session, "#{employee.name} has left the chat.")
          close_assignment(session, employee)
          transfer_session(session)
        end)

        {:ok, employee}

      error -> error
    end
  end

  def find_waiting_session_for_employee(%User{is_employee: true} = employee) do
    case get_waiting_session() do
      %Session{} = session ->
        assign_session_to_employee(session, employee)
      nil -> nil
    end
  end

  def get_waiting_session do
    from(Session,
      where: [status: :waiting],
      order_by: [asc: :inserted_at, asc: :id],
      limit: 1
    )
    |> preload([:employee])
    |> Repo.one()
  end

  defp close_assignment(%Session{} = session, %User{is_employee: true} = user) do
    from(a in Assignment,
      where: a.session_id == ^session.id and a.user_id == ^user.id and is_nil(a.unassigned_at)
    )
    |> Repo.update_all(set: [unassigned_at: DateTime.utc_now()])
  end

  def close_assignments(%Session{status: :closed} = session) do
    from(a in Assignment, where: a.session_id == ^session.id and is_nil(a.unassigned_at))
    |> Repo.update_all(set: [unassigned_at: DateTime.utc_now()])
  end

  defp transfer_session(%Session{} = session) do
    available_employees = Account.get_available_employees()
    |> Enum.reject(&(&1.id == session.employee_user_id))

    case available_employees do
      [] ->
        update_session_status(session, :waiting)
        create_system_message(session, "Please wait for assistance.")

      [new_employee | _] ->
        assign_session_to_employee(session, new_employee)
        create_system_message(session, "Care has been transferred to #{new_employee.name}.")
    end
  end

  def get_employee_status(user_id) do
    Repo.one(from(u in User, where: u.id == ^user_id and u.is_employee == true, select: u.status))
  end

  def get_active_employee_sessions(user_id) do
    from(Session, where: [employee_user_id: ^user_id, status: :active])
    |> Repo.all()
  end

  defp find_available_employee_for_session(%Session{} = session) do
    case Account.get_available_employees() do
      [] ->
        update_session_status(session, :waiting)

      [employee | _] ->
        assign_session_to_employee(session, employee)
    end
  end

  defp update_session_status(session, status) do
    session
    |> Session.status_changeset(%{status: status})
    |> Repo.update()
    |> case do
      {:ok, updated_session} ->
        broadcast_session_update(updated_session)
        {:ok, updated_session}
      error -> error
    end
  end

  defp assign_session_to_employee(%Session{} = session, %User{is_employee: true} = employee) do
    assigned_at = DateTime.utc_now()
    Multi.new()
    |> Multi.update(:session, Session.assignment_changeset(
      session,
      %{
        employee_user_id: employee.id,
        status: :active
      }
    ))
    |> Multi.update(:employee, User.assignment_changeset(
      employee,
      %{
        status: :assigned,
        last_assignment_at: assigned_at
      }
    ))
    |> Multi.insert(:assignment, Assignment.creation_changeset(
      %Assignment{},
      %{
        session_id: session.id,
        user_id: employee.id,
        assigned_at: assigned_at
      }
    ))
    |> Multi.insert(:system_message, Message.system_changeset(
      %Message{},
      %{
        session_id: session.id,
        content: "#{employee.name} has joined the chat"
      }
    ))
    |> Repo.transaction()
    |> case do
      {:ok, %{session: session, system_message: message}} ->
        broadcast_session_update(session)
        broadcast_message(Repo.preload(message, [:user, :session]))
        broadcast_assigned(session)
        {:ok, session}
      error -> error
    end
  end

  defp create_system_message(session, content) do
    %Message{}
    |> Message.system_changeset(%{session_id: session.id, content: content})
    |> Repo.insert()
    |> case do
      {:ok, message} ->
        message = Repo.preload(message, [:user, :session])
        broadcast_message(message)
        {:ok, message}
      error -> error
    end
  end

  defp broadcast_message(message) do
    PubSub.broadcast(
      MedChat.PubSub,
      "session:#{message.session_id}",
      {:new_message, message}
    )
  end

  defp broadcast_session_update(session) do
    PubSub.broadcast(
      MedChat.PubSub,
      "session:#{session.id}",
      {:session_updated, session}
    )
  end

  defp broadcast_assigned(session) do
    PubSub.broadcast(
      MedChat.PubSub,
      "waiting:#{session.employee_user_id}",
      {:assigned, session}
    )
  end

  # Convenience function for testing
  def reset_all(are_you_sure?) when are_you_sure? == true do
    Repo.delete_all(Assignment)
    Repo.delete_all(Message)
    Repo.delete_all(Session)
    Repo.update_all(User, set: [status: :unavailable])
  end
end
