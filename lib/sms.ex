defmodule AfricastalkingElixir.SMS do
  @base_url Application.get_env(
              :africastalking_elixir,
              :base_url
            ) || "https://api.sandbox.africastalking.com"

  @endpoint "#{@base_url}/version1/messaging"

  @config %{
    username: Application.get_env(:africastalking_elixir, :username),
    api_key: Application.get_env(:africastalking_elixir, :api_key)
  }
  def send(recipient, _message) when recipient == "" do
    {:error, "Recipient is required. Please provide a string number or a comma separated list of string phone numbers"}
  end

  def send(recipient, message) do
    body = %{
      username: @config.username,
      to: recipient,
      message: message
    }

    with :ok <- validate_recipient(recipient) do
      case :hackney.request(:post, @endpoint, headers(@config.api_key), URI.encode_query(body)) do
        {:ok, status, _, ref} when status in 400..599 ->
          {:ok, body} = :hackney.body(ref)
          {:error, body}
        {:ok, status, _, ref} ->
          {:ok, body} = :hackney.body(ref)
          {
            :ok,
            %{
              status_code: status,
              africastalking_response: body
                                       |> Jason.decode!
            }
          }
        {:error, reason} -> {:error, reason}
      end
    else
      error -> error
    end

  end

  defp validate_recipient(numbers) do
    if (String.split(numbers, ",")
        |> Enum.map(&String.trim/1)
        |> Enum.all?(&valid_phone?/1)) do
      :ok
    else
      {:error, "One of the phone numbers is invalid, Please check and try again"}
    end
  end

  defp valid_phone?(phone) do
    String.match?(phone, ~r/^(\+)?(\d{2,3})?0?\d{3}\d{6,7}$/)
  end

  defp headers(api_key) do
    headers = [
      {"Accept", "application/json"},
      {"apiKey", api_key},
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]
  end
end