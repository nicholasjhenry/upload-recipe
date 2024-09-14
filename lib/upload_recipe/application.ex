defmodule UploadRecipe.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      UploadRecipeWeb.Telemetry,
      UploadRecipe.Repo,
      {DNSCluster, query: Application.get_env(:upload_recipe, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: UploadRecipe.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: UploadRecipe.Finch},
      # Start a worker by calling: UploadRecipe.Worker.start_link(arg)
      # {UploadRecipe.Worker, arg},
      # Start to serve requests, typically the last entry
      UploadRecipeWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: UploadRecipe.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    UploadRecipeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
