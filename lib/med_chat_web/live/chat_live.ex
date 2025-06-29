defmodule MedChatWeb.ChatLive do
  use MedChatWeb, :live_view

  alias MedChat.Account
  alias MedChat.Chat
  alias MedChat.Chat.Message
  alias Phoenix.PubSub

  # Why a token? Because even toy apps should pretend to care about auth (even if none of the other endpoints do).
  def mount(%{"token" => token}, _session, socket) do
    %{session_id: session_id, user_id: user_id} = verify_token(token)
    session = Chat.get_session_with_associations(session_id)
    user = Account.get_user!(user_id)

    if connected?(socket) do
      PubSub.subscribe(MedChat.PubSub, topic_name(session_id))
    end

    {:ok, assign(socket,
      current_session: session,
      current_user: user,
      new_message: "",
      download_url: download_url(session),
      messages: session.messages,
      temporary_assigns: [messages: []]
    )}
  end

  def handle_event("send_message", %{"new_message" => ""}, socket) do
    {:noreply, socket, new_message: ""}
  end

  def handle_event("send_message", %{"new_message" => content}, socket) do
    {:ok, _created_message} = Chat.create_message(%{
      session_id: socket.assigns.current_session.id,
      user_id: socket.assigns.current_user.id,
      content: content
    })

    {:noreply,
      socket
      |> push_event("clear-textarea", %{id: "new_message"})
      |> assign(:new_message, "")
    }
  end

  def handle_event("employee_unavailable", _params, socket) do
    Chat.make_employee_unavailable(socket.assigns.current_user.id)
    {:noreply, push_navigate(socket, to: "/")}
  end

  def handle_event("session_ended", _params, socket) do
    Chat.close_session(
      socket.assigns.current_session,
      socket.assigns.current_user
    )
    {:noreply, push_navigate(socket, to: "/")}
  end

  def handle_info({:new_message, message}, socket) do
    updated_messages = [message]
    {:noreply, assign(socket, messages: updated_messages)}
  end

  def handle_info({:session_updated, session}, socket) do
    {:noreply, assign(socket, current_session: session)}
  end

  def message_class(message, current_user) do
    current_user_id = current_user.id
    case message.user_id do
      ^current_user_id -> "bg-sky-100" # Me
      nil -> "bg-gray-100" # System message
      _ -> "bg-green-100" # Someone else
    end
  end

  def user_name(%Message{} = message) do
    case message.type do
      :text ->
        message.user.name
      :system ->
        "System"
    end
  end

  defp verify_token(token) do
    with {:ok, value} <- MedChatWeb.Token.verify(token),
      [session_id, user_id] <- String.split(value, "|") do
        %{session_id: session_id, user_id: user_id}
    else
      _ -> raise("Token verification failed")
    end
  end

  defp topic_name(session_id) do
    "session:#{session_id}"
  end

  defp download_url(session) do
    ~p"/api/sessions/#{session}/messages"
  end
end
