defmodule ChatWeb.PageController do
  use ChatWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, user: "")
  end

  def create(conn, %{"user" => user_name}) do
    conn
    |> put_flash(:info, "You logged in successfully.")
    |> ChatWeb.UserAuth.log_in_user(user_name)
  end
end
