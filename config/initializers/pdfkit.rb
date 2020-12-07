PDFKit.configure do |config|
  config.wkhtmltopdf = '~/.rbenv/shims/wkhtmltopdf'
  config.default_options = {
    :page_size => 'A4',
    :print_media_type => true
  }
end