import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "hidden"]

  connect() {
    // Initialize with current value if any
    if (this.hiddenTarget.value) {
      this.displayTarget.value = this.formatCurrency(this.hiddenTarget.value)
    }
  }

  format(event) {
    // Get raw value (remove all non-digits)
    const rawValue = this.displayTarget.value.replace(/\D/g, '')

    // Update hidden field with raw number
    this.hiddenTarget.value = rawValue

    // Format display with dots
    this.displayTarget.value = this.formatCurrency(rawValue)
  }

  formatCurrency(value) {
    if (!value) return ''

    // Convert to string and add thousand separators
    return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.')
  }
}
