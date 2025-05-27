GDRIVE_CONFIG = {
  type: ENV['GDRIVE_TYPE'],
  project_id: ENV['GDRIVE_PROJECT_ID'],
  private_key_id: ENV['GDRIVE_PRIVATE_KEY_ID'],
  private_key: ENV['GDRIVE_PRIVATE_KEY'].gsub("\\n", "\n"),
  client_email: ENV['GDRIVE_CLIENT_EMAIL'],
  client_id: ENV['GDRIVE_CLIENT_ID'],
  auth_uri: ENV['GDRIVE_AUTH_URI'],
  token_uri: ENV['GDRIVE_TOKEN_URI'],
  auth_provider_x509_cert_url: ENV['GDRIVE_AUTH_PROVIDER_X509_CERT_URL'],
  client_x509_cert_url: ENV['GDRIVE_CLIENT_X509_CERT_URL']
}
