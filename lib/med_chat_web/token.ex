defmodule MedChatWeb.Token do
  @token_salt "something salty"

  alias Phoenix.Token
  alias MedChatWeb.Endpoint

  def sign(value) do
    Token.sign(Endpoint, @token_salt, value)
  end

  def verify(token) do
    Token.verify(Endpoint, @token_salt, token)
  end
end
