defmodule AfricastalkingElixir.SMS do
  @endpoint "https://api.sandbox.africastalking.com/version1/messaging"

  @config %{
    username: Application.get_env(:africastalking_elixir, :username),
    api_key: Application.get_env(:africastalking_elixir, :api_key)
  }

  def send(recipient, message) do
    headers = [
      {"Accept", "application/json"},
      {"apiKey", @config.api_key},
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    body = %{
      username: @config.username,
      to: recipient,
      message: message
    }
    HTTPoison.post(@endpoint, URI.encode_query(body), headers)
  end
end