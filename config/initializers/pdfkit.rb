# frozen_string_literal: true

PDFKit.configure do |config|
  config.wkhtmltopdf = '~/.rbenv/shims/wkhtmltopdf'
  config.default_options = {
    print_media_type: true,
    page_size: "A4",
    encoding: "UTF-8",
    ## Make sure the zoom option is not enabled!
    ## zoom: '1.3',
    disable_smart_shrinking: false,
    footer_right: "Page [page] of [toPage]"
  }

end
