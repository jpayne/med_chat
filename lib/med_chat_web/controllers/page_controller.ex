defmodule MedChatWeb.PageController do
  use MedChatWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def chat_session(conn, _params) do
    location = "/chat_session/" <> "12345"
    redirect(conn, to: location)
  end

  def employee_dashboard(conn, _params) do
    location = "/dashboard"
    redirect(conn, to: location)
  end
end
