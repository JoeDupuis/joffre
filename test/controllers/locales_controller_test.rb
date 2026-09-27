require "test_helper"

class LocalesControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "update requires authentication" do
    patch locale_path, params: { locale: "fr" }

    assert_redirected_to new_session_path
    assert_nil @user.reload.locale
  end

  test "update saves the locale and redirects back" do
    sign_in_as(@user)

    patch locale_path, params: { locale: "fr" }, headers: { "HTTP_REFERER" => games_url }

    assert_redirected_to games_url
    assert_equal "fr", @user.reload.locale
    assert_nil flash[:notice]
    assert_nil flash[:alert]
  end

  test "update redirects to root without a referer" do
    @user.update!(locale: "fr")
    sign_in_as(@user)

    patch locale_path, params: { locale: "en" }

    assert_redirected_to root_path
    assert_equal "en", @user.reload.locale
  end

  test "update rejects an unavailable locale" do
    sign_in_as(@user)

    patch locale_path, params: { locale: "de" }, headers: { "HTTP_REFERER" => games_url }

    assert_redirected_to games_url
    assert_equal "Your language could not be changed.", flash[:alert]
    assert_nil @user.reload.locale
  end

  test "update rejects a missing locale without clearing the saved one" do
    @user.update!(locale: "fr")
    sign_in_as(@user)

    patch locale_path, headers: { "HTTP_REFERER" => games_url }

    assert_redirected_to games_url
    assert_equal "Impossible de changer la langue.", flash[:alert]
    assert_equal "fr", @user.reload.locale
  end
end
