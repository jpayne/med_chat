defmodule MedChat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MedChatWeb.Telemetry,
      MedChat.Repo,
      {DNSCluster, query: Application.get_env(:med_chat, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: MedChat.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: MedChat.Finch},
      # Start a worker by calling: MedChat.Worker.start_link(arg)
      # {MedChat.Worker, arg},
      # Start to serve requests, typically the last entry
      MedChatWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MedChat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MedChatWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
