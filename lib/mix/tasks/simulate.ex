defmodule Mix.Tasks.Simulate do
  use Mix.Task

  @shortdoc "Simulate webhooks"
  @recursive true

  @moduledoc """
  Runs CaptainHook in a web server.

  ## Command line options

    * `-h`, `--host`     - the host to simulate on
    * `-d`, `--date`     - as a path `year`, `year/month/day/hour`
    * `-p`, `--provider` - provider to test oprovider to test onn
    * `-s`, `--segment`  - path of the url

  """
  def run(args) do
    Mix.Task.run "app.start", args
    OptionParser.parse(args, aliases: [h: :host, d: :date, p: :provider, s: :segment])
      |> elem(0)
      |> CaptainHook.Simulate.run
  end
end
