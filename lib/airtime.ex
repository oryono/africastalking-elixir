defmodule AfricastalkingElixir.Airtime do
  @base_url Application.get_env(
              :africastalking_elixir,
              :base_url
            ) || "https://api.sandbox.africastalking.com"

  @endpoint "#{@base_url}/version1/airtime/send"

  @config %{
    username: Application.get_env(:africastalking_elixir, :username),
    api_key: Application.get_env(:africastalking_elixir, :api_key)
  }


  def send(recipients) do
    body = Enum.map(
             recipients,
             fn recipient ->
               %{phoneNumber: recipient.phone_number, amount: "#{recipient.currency_code} #{recipient.amount}"}
             end
           )
           |> build_body

    with :ok <- validate_numbers(recipients), :ok <- validate_currencies(recipients) do
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

  defp headers(api_key) do
    [
      {"Accept", "application/json"},
      {"apiKey", api_key},
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]
  end

  defp build_body(recipients) do
    %{
      username: @config.username,
      recipients: Jason.encode! recipients
    }
  end

  defp validate_numbers(recipients) do
    if (Enum.all?(recipients, &valid_phone?(&1.phone_number))) do
      :ok
    else
      {:error, "One of the phone numbers is invalid, Please check and try again"}
    end
  end

  defp valid_phone?(phone) do
    String.match?(phone, ~r/^(\+)?(\d{2,3})0?\d{3}\d{6,7}$/)
  end

  defp validate_currencies(recipients) do
    if (Enum.all?(recipients, &valid_currency?(&1.currency_code))) do
      :ok
    else
      {:error, "One of the currency codes does not conform to the 3-digit ISO standard"}
    end
  end

  def valid_currency?(currency) do
    if String.length(currency) !== 3 || currency !== String.upcase(currency), do: false, else: true
  end
end