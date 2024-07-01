defmodule ChatWeb.UserAuth do
  @moduledoc false
  use ChatWeb, :verified_routes

  import Phoenix.Controller
  import Plug.Conn

  def log_in_user(conn, user) do
    conn
    |> put_user_in_session(user)
    |> redirect(to: ~p"/lobby")
  end

  def fetch_current_user(conn, _opts) do
    {user, conn} = ensure_user(conn)
    assign(conn, :current_user, user)
  end

  defp ensure_user(conn) do
    if user = get_session(conn, :current_user) do
      {user, conn}
    else
      {nil, conn}
    end
  end

  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> redirect(to: ~p"/")
      |> halt()
    end
  end

  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: ~p"/lobby")
      |> halt()
    else
      conn
    end
  end

  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(socket, session)}
  end

  defp mount_current_user(socket, session) do
    Phoenix.Component.assign_new(socket, :current_user, fn ->
      session["current_user"]
    end)
  end

  defp put_user_in_session(conn, user) do
    conn
    |> put_session(:current_user, user)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(user)}")
  end

end
