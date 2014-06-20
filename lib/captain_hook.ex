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
      IO.inspect provider
      IO.inspect body
      send_resp(conn, 202, "")
    end

    match _ do
      send_resp(conn, 404, "Not Found")
    end
  end
end
