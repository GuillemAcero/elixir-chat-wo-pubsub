defmodule Chat do
  @moduledoc """
  Chat keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def generate_chat_id(user1, user2) do
    [user1, user2]
    |> Enum.sort()
    |> Enum.join("/")
    # |> :crypto.hash(:md5)
    # |> Base.encode16(case: :lower)
  end

  def split_chat_id(id) do
    String.split(id, "/")
  end
end
