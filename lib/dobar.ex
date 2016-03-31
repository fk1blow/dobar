defmodule Dobar do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Start the endpoint when the application starts
      supervisor(Dobar.Endpoint, []),
      # Start the Ecto repository
      supervisor(Dobar.Repo, []),
      # start the interface supervisor
      supervisor(Dobar.Interface, []),
      # start capability module
      supervisor(Dobar.Kapyz, []),
      # start the intention supervisor
      supervisor(Dobar.Intent, [])
    ]

    opts = [strategy: :one_for_one, name: Dobar.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Dobar.Endpoint.config_change(changed, removed)
    :ok
  end
end
