$(document).ready(function() {
  $('body').on('click', '.ajax-request', function() {
    $($(this).closest('table#table-content')).html('<div class="col text-center">\n' +
      '  <button class="btn btn-primary">\n' +
      '    <span class="spinner-border spinner-border-sm"></span>\n' +
      '    Loading..\n' +
      '  </button>\n' +
      '</div>')
  });
  $('body').on('submit', '.ajax-form-request', function() {
    $(this).closest().find('table#table-content').html('<div class="col text-center">\n' +
      '  <button class="btn btn-primary">\n' +
      '    <span class="spinner-border spinner-border-sm"></span>\n' +
      '    Loading..\n' +
      '  </button>\n' +
      '</div>')
  });

});