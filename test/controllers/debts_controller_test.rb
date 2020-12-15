# frozen_string_literal: true

require 'test_helper'

class DebtsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @debt = debts(:one)
  end

  test 'should get index' do
    get debts_url
    assert_response :success
  end

  test 'should get new' do
    get new_debt_url
    assert_response :success
  end

  test 'should create debt' do
    assert_difference('Debt.count') do
      post debts_url,
           params: { debt: { debt_date: @debt.debt_date, debt_type: @debt.debt_type, description: @debt.description,
                             user_id: @debt.user_id, value: @debt.value } }
    end

    assert_redirected_to debt_url(Debt.last)
  end

  test 'should show debt' do
    get debt_url(@debt)
    assert_response :success
  end

  test 'should get edit' do
    get edit_debt_url(@debt)
    assert_response :success
  end

  test 'should update debt' do
    patch debt_url(@debt),
          params: { debt: { debt_date: @debt.debt_date, debt_type: @debt.debt_type, description: @debt.description,
                            user_id: @debt.user_id, value: @debt.value } }
    assert_redirected_to debt_url(@debt)
  end

  test 'should destroy debt' do
    assert_difference('Debt.count', -1) do
      delete debt_url(@debt)
    end

    assert_redirected_to debts_url
  end
end
