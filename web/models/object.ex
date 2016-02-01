defmodule OrionMedia.Object do
  defstruct [:filename, :id]
  @derive   {Phoenix.Param, key: :filename }
end