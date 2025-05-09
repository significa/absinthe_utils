defmodule AbsintheUtils.Plug.StatusCodeOverride do
  @moduledoc """
  A plug that allows overriding the HTTP status code of an Absinthe GraphQL response.

  ## Usage

  Add the plug to your pipeline:

  ```elixir
  pipeline :api do
    plug :accepts, ["json"]
    plug AbsintheUtils.Plug.StatusCodeOverride
  end
  ```

  Then in your GraphQL endpoint configuration, add the `before_send` callback:

  ```elixir
  forward "/graphql",
    Absinthe.Plug,
    schema: MyApp.Schema,
    before_send: {AbsintheUtils.Plug.StatusCodeOverride, :before_absinthe_send}
  ```

  To override the status code in a middleware, resolver, etc,
  set the `status_code_override` in the resolution context:

  ```elixir
  %{resolution | context: %{status_code_override: 500}}
  ```

  This will cause the response to have the specified HTTP status code (500 in the above example).
  """

  alias Plug.Conn
  alias Absinthe.Blueprint

  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    Plug.Conn.register_before_send(
      conn,
      fn
        conn = %Conn{private: %{absinthe_status_code_override: status_code}} ->
          Plug.Conn.put_status(conn, status_code)

        conn ->
          conn
      end
    )
  end

  @spec before_absinthe_send(Plug.Conn.t(), Absinthe.Blueprint.t()) :: Plug.Conn.t()
  def before_absinthe_send(conn, %Blueprint{
        execution: %{context: %{status_code_override: status_code_override}}
      }) do
    Conn.put_private(conn, :absinthe_status_code_override, status_code_override)
  end

  def before_absinthe_send(conn, _blueprint), do: conn
end
