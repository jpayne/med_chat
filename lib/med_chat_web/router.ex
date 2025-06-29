defmodule MedChatWeb.Router do
  use MedChatWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MedChatWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MedChatWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/patient", PageController, :patient
    get "/employee", PageController, :employee
    live "/sessions/:token", ChatLive
    live "/wait/:user_id", WaitLive
  end

  # Other scopes may use custom stacks.
  scope "/api", MedChatWeb do
    pipe_through :api

    post "/sessions/:user_id", ChatApiController, :create_session
    get "/sessions/:session_id", ChatApiController, :show_session
    post "/sessions/:session_id/messages", ChatApiController, :create_message
    get "/sessions/:session_id/messages", ChatApiController, :list_messages
    post "/sessions/:session_id/assignments", ChatApiController, :create_assignment
    get "/sessions/:session_id/assignments", ChatApiController, :list_assignments
    post "/employees/:user_id/available", ChatApiController, :employee_available
    post "/employees/:user_id/unavailable", ChatApiController, :employee_unavailable
    get "/employees/:user_id/status", ChatApiController, :get_employee_status
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:med_chat, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MedChatWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
