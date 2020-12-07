require 'test_helper'

class UserContributionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_contribution = user_contributions(:one)
  end

  test "should get index" do
    get user_contributions_url
    assert_response :success
  end

  test "should get new" do
    get new_user_contribution_url
    assert_response :success
  end

  test "should create user_contribution" do
    assert_difference('UserContribution.count') do
      post user_contributions_url, params: { user_contribution: { contribution: @user_contribution.contribution, description: @user_contribution.description, month: @user_contribution.month, pay_at: @user_contribution.pay_at, receiver_id: @user_contribution.receiver_id, user_id: @user_contribution.user_id, year: @user_contribution.year } }
    end

    assert_redirected_to user_contribution_url(UserContribution.last)
  end

  test "should show user_contribution" do
    get user_contribution_url(@user_contribution)
    assert_response :success
  end

  test "should get edit" do
    get edit_user_contribution_url(@user_contribution)
    assert_response :success
  end

  test "should update user_contribution" do
    patch user_contribution_url(@user_contribution), params: { user_contribution: { contribution: @user_contribution.contribution, description: @user_contribution.description, month: @user_contribution.month, pay_at: @user_contribution.pay_at, receiver_id: @user_contribution.receiver_id, user_id: @user_contribution.user_id, year: @user_contribution.year } }
    assert_redirected_to user_contribution_url(@user_contribution)
  end

  test "should destroy user_contribution" do
    assert_difference('UserContribution.count', -1) do
      delete user_contribution_url(@user_contribution)
    end

    assert_redirected_to user_contributions_url
  end
end
