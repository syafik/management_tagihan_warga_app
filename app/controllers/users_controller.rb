# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :set_user, only: %i[show edit update destroy]
  before_action :check_user_authorization, only: %i[edit update]
  before_action :check_invite_authorization, only: %i[create]
  skip_before_action :action_allowed, only: %i[edit update create]

  # GET /users
  # GET /users.json
  def index
    @q = User.ransack(params[:q])
    @q.sorts = 'id asc' if @q.sorts.empty?
    @pagy, @users = pagy(@q.result.includes(:addresses, :primary_address), items: 20)

    respond_to do |format|
      format.html
      format.js
    end
  end

  def search
    index
    respond_to do |format|
      format.html { redirect_to users_path }
      format.js { render 'index.js.erb' }
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show; end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit; end

  # POST /users
  # POST /users.json
  def create
    # Handle family member invitation
    if params[:invite_family_member]
      return invite_family_member
    end

    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def pic_retribution; end

  # DELETE /users/1
  # DELETE /users/1.json
  # def destroy
  #   @user.destroy
  #   respond_to do |format|
  #     format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
  #     format.json { head :no_content }
  #   end
  # end

  private

  # Handle family member invitation
  def invite_family_member
    phone_number = params[:phone_number]
    name = params[:name]
    address_id = params[:primary_address_id]

    # Validate required fields
    if phone_number.blank?
      redirect_to current_user, alert: 'Nomor telepon harus diisi.'
      return
    end

    # Check if user already exists
    existing_user = User.find_by(phone_number: phone_number)
    
    if existing_user
      # Add existing user to the same address
      user_address = existing_user.user_addresses.find_or_initialize_by(address_id: address_id)
      if user_address.persisted?
        redirect_to current_user, alert: 'Anggota keluarga sudah terdaftar di alamat ini.'
      else
        user_address.save!
        redirect_to current_user, notice: 'Anggota keluarga berhasil ditambahkan.'
      end
    else
      # Create new user
      # Generate 8-character password with numbers and letters
      password = "#{rand(1000..9999)}#{('a'..'z').to_a.sample(4).join}"
      login_code = rand(100000..999999).to_s
      
      new_user = User.create!(
        phone_number: phone_number,
        name: name.presence || "User #{phone_number}",
        email: "#{phone_number}@example.com", # Temporary email
        password: password,
        role: 1, # Warga role
        login_code: login_code
      )
      
      # Add user to address
      new_user.user_addresses.create!(address_id: address_id)
      
      # Send WhatsApp invitation notification with address info
      address = Address.find(address_id)
      new_user.send_invitation_notification!(address)
      
      redirect_to user_path(current_user), notice: "Undangan berhasil dikirim!"
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params[:id])
  end

  # Authorization check for edit/update actions
  def check_user_authorization
    unless current_user.is_admin? || current_user == @user
      redirect_to root_path, alert: 'You are not authorized to perform this action.'
    end
  end

  # Authorization check for create action (invite family member)
  def check_invite_authorization
    if params[:invite_family_member]
      unless current_user.is_warga?
        redirect_to root_path, alert: 'Only warga users can invite family members.'
        return
      end
    else
      # For regular user creation, only admin can create
      unless current_user.is_admin?
        redirect_to root_path, alert: 'You are not authorized to perform this action.'
        return
      end
    end
  end

  # Only allow a list of trusted parameters through.
  def user_params
    # Restrict parameters based on user role
    if current_user.is_warga? && current_user == @user
      # Warga users can only edit their own basic profile info
      params.fetch(:user, {}).permit(:email, :name, :phone_number, :avatar)
    else
      # Admin users can edit all fields
      params.fetch(:user, {}).permit(:email, :name, :phone_number, :password, :contribution, :block_address, :role,
                                     :pic_blok, :avatar, :address_id, address_ids: [])
    end
  end
end
