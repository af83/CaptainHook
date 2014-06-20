defmodule Mix.Tasks.Server do
  use Mix.Task

  @shortdoc "Run CaptainHook in a web server"
  @recursive true

  @moduledoc """
  Runs CaptainHook in a web server.

  ## Command line options

    * `-p`, `--port` - the port to listen to

  """
  def run(args) do
    opts = OptionParser.parse(args, aliases: [p: :port]) |> elem(0)

    if opts[:port] do
      opts = Keyword.update!(opts, :port, &binary_to_integer(&1))
    end

    Mix.Task.run "app.start", args
    CaptainHook.run(opts)

    unless Code.ensure_loaded?(IEx) && IEx.started? do
      :timer.sleep(:infinity)
    end
  end
end
