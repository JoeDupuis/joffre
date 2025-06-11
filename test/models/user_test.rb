require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should require name" do
    user = User.new(email_address: "test@example.com", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "should require email" do
    user = User.new(name: "Test User", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "should require valid email format" do
    user = User.new(name: "Test User", email_address: "invalid_email", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "is invalid"
  end

  test "should require unique email" do
    existing_user = users(:one)
    user = User.new(name: "Test User", email_address: existing_user.email_address, password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "has already been taken"
  end

  test "should normalize email address" do
    user = User.new(name: "Test User", email_address: "  TEST@EXAMPLE.COM  ", password: "password123")
    user.valid?
    assert_equal "test@example.com", user.email_address
  end

  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end
end
