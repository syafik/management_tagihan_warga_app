class AppSettingsController < ApplicationController
  before_action :set_app_setting, only: [:show, :edit, :update, :destroy]

  # GET /app_settings
  # GET /app_settings.json
  def index
    @q = AppSetting.ransack(params[:q])
    @q.sorts = 'id asc' if @q.sorts.empty?
    @app_settings = @q.result.page(params[:page])

    respond_to do |format|
      format.html
      format.js
    end
  end

  def search
    index
    respond_to do |format|
      format.html { redirect_to app_settings_path }
      format.js { render 'index.js.erb' }
    end
  end

  # GET /app_settings/1
  # GET /app_settings/1.json
  def show
  end

  # GET /app_settings/new
  def new
    @app_setting = AppSetting.new
  end

  # GET /app_settings/1/edit
  def edit
  end

  # POST /app_settings
  # POST /app_settings.json
  def create
    @app_setting = AppSetting.new(app_setting_params)

    respond_to do |format|
      if @app_setting.save
        format.html { redirect_to @app_setting, notice: 'App setting was successfully created.' }
        format.json { render :show, status: :created, location: @app_setting }
      else
        format.html { render :new }
        format.json { render json: @app_setting.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /app_settings/1
  # PATCH/PUT /app_settings/1.json
  def update
    respond_to do |format|
      if @app_setting.update(app_setting_params)
        format.html { redirect_to @app_setting, notice: 'App setting was successfully updated.' }
        format.json { render :show, status: :ok, location: @app_setting }
      else
        format.html { render :edit }
        format.json { render json: @app_setting.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /app_settings/1
  # DELETE /app_settings/1.json
  def destroy
    @app_setting.destroy
    respond_to do |format|
      format.html { redirect_to app_settings_url, notice: 'App setting was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_app_setting
      @app_setting = AppSetting.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def app_setting_params
      params.require(:app_setting).permit(:home_page_text)
    end
end
