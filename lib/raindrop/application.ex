defmodule Raindrop.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(RaindropWeb.Endpoint, []),
      # Start your own worker by calling: Raindrop.Worker.start_link(arg1, arg2, arg3)
      # worker(Raindrop.Worker, [arg1, arg2, arg3]),
      {Lace.Redis, %{redis_ip: System.get_env("REDIS_IP"), redis_port: 6379, pool_size: 10, redis_pass: System.get_env("REDIS_PASS")}},
      {Lace, %{name: System.get_env("NODE_NAME"), group: System.get_env("GROUP_NAME"), cookie: System.get_env("COOKIE")}},
      {Raindrop.Generator, %{epoch: String.to_integer(System.get_env("EPOCH"))}},
      {Task.Supervisor, name: Raindrop.Tasks}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Raindrop.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    RaindropWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
