# frozen_string_literal: true

class ContributionsController < ApplicationController
  before_action :set_contribution, only: %i[show edit update destroy]

  # GET /contributions
  # GET /contributions.json
  def index
    @q = Contribution.ransack(params[:q])
    @q.sorts = 'effective_from desc' if @q.sorts.empty?
    @contributions = @q.result.page(params[:page])

    respond_to do |format|
      format.html
      format.js
    end
  end

  def search
    index
    respond_to do |format|
      format.html { redirect_to contributions_path }
      format.js { render 'index.js.erb' }
    end
  end

  # GET /contributions/1
  # GET /contributions/1.json
  def show; end

  # GET /contributions/new
  def new
    @contribution = Contribution.new
    @contribution.effective_from = Date.current
    @contribution.active = true
  end

  # GET /contributions/1/edit
  def edit; end

  # POST /contributions
  # POST /contributions.json
  def create
    @contribution = Contribution.new(contribution_params)

    respond_to do |format|
      if @contribution.save
        format.html { redirect_to @contribution, notice: 'Contribution rate was successfully created.' }
        format.json { render :show, status: :created, location: @contribution }
      else
        format.html { render :new }
        format.json { render json: @contribution.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /contributions/1
  # PATCH/PUT /contributions/1.json
  def update
    respond_to do |format|
      if @contribution.update(contribution_params)
        format.html { redirect_to @contribution, notice: 'Contribution rate was successfully updated.' }
        format.json { render :show, status: :ok, location: @contribution }
      else
        format.html { render :edit }
        format.json { render json: @contribution.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /contributions/1
  # DELETE /contributions/1.json
  def destroy
    @contribution.destroy
    respond_to do |format|
      format.html { redirect_to contributions_url, notice: 'Contribution rate was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_contribution
    @contribution = Contribution.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def contribution_params
    params.require(:contribution).permit(:amount, :effective_from, :block, :description, :active)
  end
end
