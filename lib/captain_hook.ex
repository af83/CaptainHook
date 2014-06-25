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

    get "/dropbox" do
      conn = Plug.Conn.fetch_params(conn)
      send_resp(conn, 200, conn.params["challenge"])
    end

    match _ do
      send_resp(conn, 200, "")
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

  defmodule Simulate do
    def run(options) do
      provider = options[:provider] || providers
      host     = options[:host]
      date     = options[:date]
      path     = options[:segment] || ":provider"
      simulate(provider, host, path, date)
    end

    def simulate(providers, host, path, date) when is_list(providers) do
      Parallel.pmap(providers, fn(provider) -> simulate(provider, host, path, date) end)
    end

    def simulate(provider, host, path, date) do
      Path.absname("hooks")
        |> Path.join(provider)
        |> Path.join(date || "")
        |> Path.join("**/*.hook")
        |> Path.wildcard
        |> post(host, String.replace(path, ":provider", provider))
    end

    defp post(files, host, path) when is_list(files) do
      Enum.each(files, fn(file) -> post(file, host, path) end)
    end

    defp post(file, host, path) do
      {:ok, body} = File.read(file)
      Path.join(host, path)
        |> HTTPotion.post(body)
        |> log(path)
    end

    defp log(response, provider) do
      date = Timex.Date.now |> Timex.DateFormat.format!("{RFC1123}")
      IO.inspect "[#{provider}] #{date} #{response.status_code}"
    end

    defp providers do
      Path.absname("hooks")
        |> Path.join("*")
        |> Path.wildcard
        |> Enum.map(fn(dir) -> Path.basename(dir) end)
    end
  end
end

defmodule Parallel do
  def pmap(collection, fun) do
    me = self

    collection
      |> Enum.map(fn (elem) -> spawn_link fn -> (send me, { self, fun.(elem)}) end end)
      |> Enum.map(fn (pid) -> receive do { ^pid, result } -> result end end)
  end
end
