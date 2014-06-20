defmodule CaptainHook do
  def run(opts) do
    port = Keyword.get(opts, :port, 4000)
    IO.puts "Running CaptainHook with Cowboy on http://localhost:#{port}"
    Plug.Adapters.Cowboy.http CaptainHook.Router, [], opts
  end

  defmodule Router do
    import Plug.Conn
    use Plug.Router

    plug :match
    plug :dispatch

    post ":provider" do
      {:ok, body, conn} = read_body(conn)
      case build_path(provider) |> File.write(body) do
        {:error, :enoent} -> mkdir_and_retry(provider, body)
        _                 -> :ok
      end
      send_resp(conn, 202, "")
    end

    match _ do
      send_resp(conn, 404, "Not Found")
    end

    defp build_directory(provider) do
      date = Timex.Date.now
      Path.absname("hooks")
        |> Path.join(provider |> to_string)
        |> Path.join(date.year |> to_string)
        |> Path.join(date.month |> to_string)
        |> Path.join(date.day |> to_string)
        |> Path.join(date.hour |> to_string)
    end

    defp build_path(provider) do
      build_directory(provider)
        |> Path.join([uuid, ".hook"])
    end

    defp uuid do
      String.replace(to_string(:uuid.to_string(:uuid.v4())), "-", "")
    end

    defp mkdir_and_retry(provider, body) do
      build_directory(provider) |> File.mkdir_p!
      build_path(provider) |> File.write(body)
    end
  end
end
