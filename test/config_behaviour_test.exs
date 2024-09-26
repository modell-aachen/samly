defmodule Samly.ConfigBehaviourTest do
  use Samly.RouterCase

  def get_idp(_conn, idp_id) do
    service_providers = Samly.SpData.load_providers([@sp_config])
    config = Samly.IdpData.load_providers([@idp_config], service_providers)
    config[idp_id]
  end

  setup do
    Application.put_env(:samly, :config_provider, Samly.ConfigBehaviourTest)
    setup_providers([], [])
  end

  test "GET on signin uri returns saml html form" do
    conn(:get, "/signin/idp1")
    |> init_test_session(%{})
    |> AuthRouter.call([])
    |> assert_initial_saml_form("%2F")
  end
end
