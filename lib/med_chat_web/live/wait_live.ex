defmodule MedChatWeb.WaitLive do
  use MedChatWeb, :live_view
  import MedChatWeb.SharedHelpers

  alias MedChat.Chat
  alias MedChat.Account
  alias Phoenix.PubSub

  def mount(%{"user_id" => user_id}, _session, socket) do
    user = Account.get_employee!(user_id)
    Chat.make_employee_available(user.id)

    # Is there already a waiting session?
    case Chat.find_waiting_session_for_employee(user) do
      {:ok, session} ->
        # Let's go...
        {:ok, push_navigate(socket, to: session_location_for_user(session, user))}
      _ ->
        # Otherwise, subscribe to be notified of a future assignment
        if connected?(socket), do: PubSub.subscribe(MedChat.PubSub, "waiting:#{user.id}")
        {:ok, assign(socket, current_user: user)}
    end
  end

  # Handler for redirecting to a new assignment
  def handle_info({:assigned, session}, socket) do
    location = session_location_for_user(session, socket.assigns.current_user)
    {:noreply, push_navigate(socket, to: location)}
  end
end
