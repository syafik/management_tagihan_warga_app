import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["roleSelect", "addressBox", "picBox", "addressSelect"]

  connect() {
    // Initialize select2 if available
    if (typeof $ !== 'undefined' && $.fn.select2) {
      $(".select-field-js").select2();
    }
    this.toggleFields()
  }

  disconnect() {
    // Clean up select2 if it was initialized
    if (typeof $ !== 'undefined' && $.fn.select2) {
      $(".select-field-js").select2('destroy');
    }
  }

  roleChanged() {
    this.toggleFields()
  }

  toggleFields() {
    const roleValue = this.roleSelectTarget.value
    
    if (roleValue === '3') { // Security role
      this.addressBoxTarget.classList.add('hidden')
      this.addressSelectTarget.value = ''
      // Trigger change event if select2 is available
      if (typeof $ !== 'undefined' && $.fn.select2) {
        $(this.addressSelectTarget).trigger('change')
      }
      this.picBoxTarget.classList.remove('hidden')
      this.picBoxTarget.querySelector('input').value = ''
    } else {
      this.addressBoxTarget.classList.remove('hidden')
      this.picBoxTarget.classList.add('hidden')
    }
  }
}