defmodule Bridge.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    {result, _} =
      "BRIDGE_TEAMS"
      |> System.get_env
      |> Code.eval_string
    children =
      result
      |> Enum.with_index
      |> Enum.map(fn {team, index} -> %{
        id: index,
        start: {Slack.Bot, :start_link, [Bridge.Bot, team, team.token]}
      } end)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bridge.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
