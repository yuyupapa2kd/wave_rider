require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "redirects dashboard to login when unauthenticated" do
    get root_path

    assert_redirected_to new_session_path
  end

  test "allows configured admin login" do
    post session_path, params: { username: "admin", password: "change-me" }

    assert_redirected_to root_path
  end

  test "rejects wrong credentials" do
    post session_path, params: { username: "admin", password: "wrong" }

    assert_response :unprocessable_entity
  end
end
