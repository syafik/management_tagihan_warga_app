# frozen_string_literal: true

class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin

  def backup_database
    return unless current_user&.is_admin?

    begin
      # Generate filename with timestamp
      timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
      filename = "puri_ayana_backup_#{timestamp}.sql"
      
      # Get database configuration
      db_config = ActiveRecord::Base.connection_db_config.configuration_hash
      Rails.logger.info "Database config: #{db_config.except(:password)}"
      
      # Build pg_dump command with full path
      pg_dump_path = `which pg_dump`.strip
      pg_dump_path = '/opt/homebrew/opt/postgresql@15/bin/pg_dump' if pg_dump_path.empty?
      
      command = [pg_dump_path, '--no-owner', '--no-privileges', '--clean', '--if-exists']
      
      # Add host only if specified in config
      command += ['--host', db_config[:host]] if db_config[:host].present?
      
      # Add port only if specified in config  
      command += ['--port', db_config[:port].to_s] if db_config[:port].present?
      
      # Add username and database
      command += ['--username', db_config[:username]] if db_config[:username].present?
      command += ['--dbname', db_config[:database]]
      
      # Set PGPASSWORD environment variable
      env = { 'PGPASSWORD' => db_config[:password] }
      
      Rails.logger.info "Executing pg_dump command..."
      # Execute pg_dump command
      sql_output, error_output, status = Open3.capture3(env, *command)
      
      Rails.logger.info "Command status: #{status.success?}"
      Rails.logger.info "Output size: #{sql_output.size} bytes"
      Rails.logger.info "Error output: #{error_output}" if error_output.present?
      
      if status.success? && sql_output.present?
        # Send file as download
        respond_to do |format|
          format.html do
            send_data sql_output,
                      filename: filename,
                      type: 'application/octet-stream',
                      disposition: 'attachment'
          end
        end
        return
      else
        error_msg = error_output.present? ? error_output : 'No output generated'
        Rails.logger.error "Database backup failed: #{error_msg}"
        redirect_to root_path, alert: "Gagal membuat backup database: #{error_msg}"
        return
      end
      
    rescue StandardError => e
      Rails.logger.error "Database backup error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      redirect_to root_path, alert: "Terjadi kesalahan saat membuat backup: #{e.message}"
    end
  end

  private

  def ensure_admin
    unless current_user&.is_admin?
      redirect_to root_path, alert: 'Akses ditolak. Hanya admin yang dapat mengakses fitur ini.'
    end
  end
end