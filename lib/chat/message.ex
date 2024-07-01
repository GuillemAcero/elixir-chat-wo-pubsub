defmodule Chat.Message do
  defstruct [
    :action,
    :message,
    :user_id,
    :timestamp
  ]

  @type t :: %__MODULE__{
          action: atom(),
          message: String.t(),
          user_id: String.t(),
          timestamp: DateTime.t()
        }

  def new(action, user_id, timestamp, message \\ "") when is_atom(action) and is_binary(message) and is_binary(user_id) and is_struct(timestamp, DateTime) do
    %__MODULE__{
      action: action,
      message: message,
      user_id: user_id,
      timestamp: timestamp
    }
  end

end
