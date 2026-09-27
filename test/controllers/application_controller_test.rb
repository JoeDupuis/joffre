require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "saved user locale wins over the Accept-Language header" do
    @user.update!(locale: "fr")
    sign_in_as(@user)

    get root_path, headers: { "Accept-Language" => "en-US,en;q=0.9" }

    assert_response :success
    assert_select "html[lang=fr]"
  end

  test "saved english locale wins over a french Accept-Language header" do
    @user.update!(locale: "en")
    sign_in_as(@user)

    get root_path, headers: { "Accept-Language" => "fr-CA,fr;q=0.9" }

    assert_select "html[lang=en]"
  end

  test "saved user locale applies on pages that allow unauthenticated access" do
    @user.update!(locale: "fr")
    sign_in_as(@user)

    get new_session_path, headers: { "Accept-Language" => "en" }

    assert_select "html[lang=fr]"
  end

  test "Accept-Language header is used when the user has no saved locale" do
    sign_in_as(@user)

    get root_path, headers: { "Accept-Language" => "fr-CA,fr;q=0.9,en;q=0.8" }

    assert_select "html[lang=fr]"
  end

  test "Accept-Language header is used when signed out" do
    get new_session_path, headers: { "Accept-Language" => "fr-CA,fr;q=0.9,en;q=0.8" }

    assert_select "html[lang=fr]"
  end

  test "Accept-Language header picks the highest quality available language" do
    get new_session_path, headers: { "Accept-Language" => "de;q=1.0,en;q=0.5,fr;q=0.8" }

    assert_select "html[lang=fr]"
  end

  test "Accept-Language header ignores languages with a zero quality" do
    get new_session_path, headers: { "Accept-Language" => "fr;q=0,en;q=0.1" }

    assert_select "html[lang=en]"
  end

  test "default locale is used without a header" do
    get new_session_path

    assert_select "html[lang=en]"
  end

  test "default locale is used when no header language is available" do
    get new_session_path, headers: { "Accept-Language" => "de-DE,es;q=0.8,*;q=0.5" }

    assert_select "html[lang=en]"
  end

  test "authentication still redirects with a locale header" do
    get root_path, headers: { "Accept-Language" => "fr" }

    assert_redirected_to new_session_path
  end

  test "locale does not leak past the request" do
    get new_session_path, headers: { "Accept-Language" => "fr" }

    assert_select "html[lang=fr]"
    assert_equal :en, I18n.locale
  end
end
