defmodule Samly.SPRouterTest do
  use ExUnit.Case
  use Plug.Test

  alias Samly.SPRouter
  alias Samly.Provider

  @sp_config %{
    id: "sp1",
    entity_id: "urn:test:sp1",
    certfile: "test/data/test.crt",
    keyfile: "test/data/test.pem"
  }

  @idp_config %{
    id: "idp1",
    sp_id: "sp1",
    base_url: "http://samly.howto:4003/sso",
    metadata_file: "test/data/idp_metadata.xml"
  }

  setup do
    Application.put_env(:samly, Provider,
      service_providers: [@sp_config],
      identity_providers: [@idp_config]
    )

    on_exit(fn ->
      Application.delete_env(:samly, Provider)
    end)

    Provider.init([])
    :ok
  end

  # test "GET on signin uri returns saml html form" do
  #   conn(:post, "/consume/idp1")
  #   |> init_test_session(%{})
  #   |> SPRouter.call([])
  # end
end
