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

  defmodule Simulate do
    def run(options) do
      provider = options[:provider] || providers
      host     = options[:host]
      date     = options[:date]
      simulate(provider, host, date)
    end

    def simulate(providers, host, date) when is_list(providers) do
      Parallel.pmap(providers, fn(provider) -> simulate(provider, host, date) end)
    end

    def simulate(provider, host, date) do
      Path.absname("hooks")
        |> Path.join(provider)
        |> Path.join(date || "")
        |> Path.join("**/*.hook")
        |> Path.wildcard
        |> post(host, provider)
    end

    defp post(files, host, provider) when is_list(files) do
      Enum.each(files, fn(file) -> post(file, host, provider) end)
    end

    defp post(file, host, provider) do
      {:ok, body} = File.read(file)
      Path.join(host, provider)
        |> HTTPotion.post(body)
        |> log(provider)
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
