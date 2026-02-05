import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "hidden"]
  static values = {
    prefix: String
  }

  connect() {
    // Initialize with current value if any
    if (this.hiddenTarget.value) {
      const rawValue = this.normalizeValue(this.hiddenTarget.value)
      this.hiddenTarget.value = rawValue
      this.displayTarget.value = this.formatCurrency(rawValue)
    }
  }

  format(event) {
    // Get raw value (remove all non-digits)
    const rawValue = this.normalizeValue(this.displayTarget.value)

    // Update hidden field with raw number
    this.hiddenTarget.value = rawValue

    // Format display with dots
    this.displayTarget.value = this.formatCurrency(rawValue)
  }

  formatCurrency(value) {
    if (!value) return ''

    // Convert to string and add thousand separators
    const formattedValue = value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.')
    return this.prefixValue ? `${this.prefixValue} ${formattedValue}` : formattedValue
  }

  normalizeValue(value) {
    return value.toString().replace(/\D/g, '')
  }
}
