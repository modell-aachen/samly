defmodule Samly.AuthRouterTest do
  use ExUnit.Case
  use Plug.Test

  import SweetXml

  alias Samly.AuthRouter
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
      Application.delete_env(:samly, :service_providers)
      Application.delete_env(:samly, :identity_providers)
    end)

    Provider.init([])
    :ok
  end

  test "GET on signin uri returns saml html form" do
    conn(:get, "/signin/idp1")
    |> init_test_session(%{})
    |> AuthRouter.call([])
    |> assert_initial_saml_form("%2F")
  end

  test "GET on signin uri returns saml html form with the given target url" do
    conn(:get, "/signin/idp1", target_url: "/Glossary")
    |> init_test_session(%{})
    |> AuthRouter.call([])
    |> assert_initial_saml_form("%2FGlossary")
  end

  test "POST on signin uri returns form that will be submited to idp" do
    assert ~c"urn:test:sp1" =
             conn(:post, "/signin/idp1", %{RelayState: "OOhdIq-_PagPusisHCjYBZsYSwr-bVUs"})
             |> put_private(:plug_skip_csrf_protection, true)
             |> put_private(:samly_nonce, "1mv+7BUs8o1nkOxa6ufS6kJ")
             |> init_test_session(%{})
             |> AuthRouter.call([])
             |> assert_form("POST", "http://samly.idp:8082/simplesaml/saml2/idp/SSOService.php")
             |> Floki.attribute("input[name=SAMLRequest]", "value")
             |> List.first()
             |> Base.decode64!()
             |> SweetXml.parse()
             |> SweetXml.xpath(~x"//saml:Issuer/text()")
  end

  defp assert_form(conn, method, action) do
    assert conn.status == 200
    assert conn.method == method

    form = Floki.parse_document!(conn.resp_body) |> Floki.find("form")
    assert [^action] = Floki.attribute(form, "action")
    assert ["post"] = Floki.attribute(form, "method")

    form
  end

  defp assert_initial_saml_form(conn, target_url) do
    assert [^target_url] =
             assert_form(conn, "GET", "/signin/idp1")
             |> Floki.attribute("input[name=target_url]", "value")
  end
end
