defmodule AbsintheUtilsTest.Helpers.Errors do
  @doc """
  Given an absinthe resolution puts an error and marks the resolution as resolved.
  """
  def put_error(resolution, message, code) when is_binary(code) do
    put_error(
      resolution,
      message,
      %{code: code}
    )
  end

  def put_error(resolution, message, extra) when is_map(extra) do
    Absinthe.Resolution.put_result(
      resolution,
      {
        :error,
        %{
          message: message,
          extensions: extra
        }
      }
    )
  end
end
