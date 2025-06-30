defmodule MedChatWeb.ChatApiController do
  use MedChatWeb, :controller

  alias MedChat.Chat
  alias MedChat.Chat.Message
  alias MedChat.Account.User

  def create_session(conn, %{"user_id" => user_id}) do
    case Chat.create_session(user_id) do
      {:ok, session} ->
        location = ~p"/sessions/#{session}"
        conn
        |> put_status(:created)
        |> put_resp_header("location", location)
        |> json(%{
          session_id: session.id,
          user_id: user_id,
          location: location,
          started_at: session.inserted_at
        })
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          error: changeset.errors
        })
    end
  end

  def show_session(conn, %{"session_id" => session_id}) do
    session = Chat.get_session_with_associations(session_id)
    conn
    |> put_status(:ok)
    |> json(%{
      session_id: session.id,
      status: session.status,
      started_at: session.inserted_at,
      messages: messages_json(session.messages),
      patient: user_json(session.patient),
      employee: user_json(session.employee)
    })
  end

  def create_message(conn,
    %{
      "session_id" => session_id,
      "user_id" => user_id,
      "content" => content
    })
  do
    case Chat.create_message(%{
      session_id: session_id,
      user_id: user_id,
      content: content
    }) do
      {:ok, message} ->
        conn
        |> put_status(:created)
        |> json(%{
          session_id: message.session_id,
          message_id: message.id,
          user_id: message.user_id,
          content: message.content,
          length: String.length(content)
        })
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          error: changeset_errors_to_json(changeset)
        })
    end
  end

  def list_messages(conn, %{"session_id" => session_id}) do
    messages =
      Chat.list_messages(session_id)
      |> Enum.map(fn message ->
        message_json(message)
      end)

    conn
    |> put_status(:ok)
    |> json(%{
      session_id: session_id,
      messages: messages
    })
  end

  def create_assignment(conn, %{"session_id" => session_id, "user_id" => user_id}) do
    case Chat.create_assignment(session_id, user_id) do
      {:ok, assignment} ->
        conn
        |> put_status(:created)
        |> json(%{
          assignment_id: assignment.id,
          assigned_at: assignment.assigned_at,
          user_id: assignment.user.id,
          session_id: assignment.session_id
        })

      {:error, error} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          error: error
        })
    end
  end

  def list_assignments(conn, %{"session_id" => session_id}) do
    assignments =
      Chat.list_assignments(session_id)
      |> Enum.map(fn assignment ->
        %{
          assignment_id: assignment.id,
          user_id: assignment.user_id,
          assigned_at: assignment.assigned_at
        }
      end)

    conn
    |> put_status(:ok)
    |> json(%{
      session_id: session_id,
      assignments: assignments
    })
  end

  def employee_available(conn, %{"user_id" => user_id}) do
    Chat.make_employee_available(user_id)
    conn
    |> put_status(:ok)
    |> json(%{
      employee: %{
        user_id: user_id,
        status: "available (waiting)"
      }
    })
  end

  def employee_unavailable(conn, %{"user_id" => user_id}) do
    Chat.make_employee_unavailable(user_id)
    conn
    |> put_status(:ok)
    |> json(%{
      employee: %{
        user_id: user_id,
        status: "unavailable"
      }
    })
  end

  def get_employee_status(conn, %{"user_id" => user_id}) do
    status = case Chat.get_employee_status(user_id) do
      :waiting -> "available (waiting)"
      other -> other
    end
    conn
    |> put_status(:ok)
    |> json(%{
      employee: %{
        user_id: user_id,
        status: status
      }
    })
  end

  ### JSON helpers ###

  defp messages_json(messages) do
    Enum.map(messages, fn message ->
      message_json(message)
    end)
  end

  defp message_json(%Message{} = message) do
    case message.type do
      :text ->
        %{
          message_id: message.id,
          content: message.content,
          user_name: message.user.name,
          user_id: message.user.id,
          type: message.type,
          timestamp: message.inserted_at
        }
      :system ->
        %{
          message_id: message.id,
          content: message.content,
          type: message.type,
          timestamp: message.inserted_at
        }
    end
  end

  defp user_json(user) do
    with %User{id: id, name: name} <- user do
      %{
        user_id: id,
        name: name
      }
    end
  end

  defp changeset_errors_to_json(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &changeset_error_to_string/1)
  end

  defp changeset_error_to_string({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
