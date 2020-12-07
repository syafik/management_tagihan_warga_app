require "application_system_test_case"

class UserContributionsTest < ApplicationSystemTestCase
  setup do
    @user_contribution = user_contributions(:one)
  end

  test "visiting the index" do
    visit user_contributions_url
    assert_selector "h1", text: "User Contributions"
  end

  test "creating a User contribution" do
    visit user_contributions_url
    click_on "New User Contribution"

    fill_in "Contribution", with: @user_contribution.contribution
    fill_in "Description", with: @user_contribution.description
    fill_in "Month", with: @user_contribution.month
    fill_in "Pay At", with: @user_contribution.pay_at
    fill_in "Receiver", with: @user_contribution.receiver_id
    fill_in "User", with: @user_contribution.user_id
    fill_in "Year", with: @user_contribution.year
    click_on "Create User contribution"

    assert_text "User contribution was successfully created"
    click_on "Back"
  end

  test "updating a User contribution" do
    visit user_contributions_url
    click_on "Edit", match: :first

    fill_in "Contribution", with: @user_contribution.contribution
    fill_in "Description", with: @user_contribution.description
    fill_in "Month", with: @user_contribution.month
    fill_in "Pay At", with: @user_contribution.pay_at
    fill_in "Receiver", with: @user_contribution.receiver_id
    fill_in "User", with: @user_contribution.user_id
    fill_in "Year", with: @user_contribution.year
    click_on "Update User contribution"

    assert_text "User contribution was successfully updated"
    click_on "Back"
  end

  test "destroying a User contribution" do
    visit user_contributions_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "User contribution was successfully destroyed"
  end
end
