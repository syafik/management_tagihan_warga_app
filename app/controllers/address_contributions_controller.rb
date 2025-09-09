# frozen_string_literal: true

# Controller for managing address-specific contribution rates
class AddressContributionsController < ApplicationController
  before_action :set_address
  before_action :set_address_contribution, only: %i[show edit update destroy]

  # GET /addresses/:address_id/address_contributions
  def index
    @address_contributions = @address.address_contributions.includes(:address)
  end

  # GET /addresses/:address_id/address_contributions/1
  def show; end

  # GET /addresses/:address_id/address_contributions/new
  def new
    @address_contribution = @address.address_contributions.build
  end

  # GET /addresses/:address_id/address_contributions/1/edit
  def edit; end

  # POST /addresses/:address_id/address_contributions
  def create
    @address_contribution = @address.address_contributions.build(address_contribution_params)

    if @address_contribution.save
      redirect_to [@address, @address_contribution], 
                  notice: 'Address contribution was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /addresses/:address_id/address_contributions/1
  def update
    if @address_contribution.update(address_contribution_params)
      redirect_to [@address, @address_contribution], 
                  notice: 'Address contribution was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /addresses/:address_id/address_contributions/1
  def destroy
    @address_contribution.destroy
    redirect_to address_address_contributions_url(@address), 
                notice: 'Address contribution was successfully deleted.'
  end

  private

  def set_address
    @address = Address.find(params[:address_id])
  end

  def set_address_contribution
    @address_contribution = @address.address_contributions.find(params[:id])
  end

  def address_contribution_params
    params.require(:address_contribution).permit(:amount, :effective_from, :effective_until, :reason, :active)
  end
end