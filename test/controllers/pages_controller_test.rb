require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get home" do
    get home_path
    assert_response :success
  end

  test "should get about" do
    get about_path
    assert_response :success
  end

  test "should get services" do
    get services_path
    assert_response :success
  end

  test "should get portfolio" do
    get portfolio_path
    assert_response :success
  end

  test "should get contact" do
    get contact_path
    assert_response :success
  end
end
