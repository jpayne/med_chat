defmodule MedChatWeb.PageController do
  use MedChatWeb, :controller

  import Ecto.Query
  import MedChatWeb.SharedHelpers

  alias MedChat.Repo
  alias MedChat.Account.User
  alias MedChat.Chat

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home)
  end

  def patient(conn, _params) do
    patient = random_patient()
    case Chat.create_session(patient.id) do
      {:ok, session} ->
        redirect(conn, to: session_location_for_user(session, patient))

      {:error, error} -> text(conn, error)

      _ -> text(conn, "Failed to create chat session.")
    end
  end

  def employee(conn, _params) do
    user = random_employee()
    redirect(conn, to: ~p"/wait/#{user.id}")
  end

  ### Silly demo functions ###

  defp random_employee do
    Repo.one(
      from User,
      where: [is_employee: true, status: :unavailable],
      order_by: fragment("RANDOM()"),
      limit: 1
    )
  end

  defp random_patient do
    Repo.one(
      from User,
      where: [is_employee: false],
      order_by: fragment("RANDOM()"),
      limit: 1
    )
  end
end
