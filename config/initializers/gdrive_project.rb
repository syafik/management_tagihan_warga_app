GDRIVE_CONFIG = {
  type: Rails.application.credentials.dig(:gdrive, :type),
  project_id: Rails.application.credentials.dig(:gdrive, :project_id),
  private_key_id: Rails.application.credentials.dig(:gdrive, :private_key_id),
  private_key: Rails.application.credentials.dig(:gdrive, :private_key),
  client_email: Rails.application.credentials.dig(:gdrive, :client_email),
  client_id: Rails.application.credentials.dig(:gdrive, :client_id),
  auth_uri: Rails.application.credentials.dig(:gdrive, :auth_uri),
  token_uri: Rails.application.credentials.dig(:gdrive, :token_uri),
  auth_provider_x509_cert_url: Rails.application.credentials.dig(:gdrive, :auth_provider_x509_cert_url),
  client_x509_cert_url: Rails.application.credentials.dig(:gdrive, :client_x509_cert_url)
}
