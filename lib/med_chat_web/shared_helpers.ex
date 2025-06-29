defmodule MedChatWeb.SharedHelpers do
  use MedChatWeb, :verified_routes

  alias MedChat.Chat.Session
  alias MedChat.Account.User

  def session_location_for_user(%Session{} = session, %User{} = user) do
    ~p"/sessions/#{session_token_for_user(session, user)}"
  end

  def session_token_for_user(%Session{} = session, %User{} = user) do
    MedChatWeb.Token.sign("#{session.id}|#{user.id}")
  end
end
