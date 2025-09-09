import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    autoDismiss: Boolean,
    timeout: Number
  }

  connect() {
    if (this.autoDismissValue) {
      this.timeoutId = setTimeout(() => {
        this.dismiss()
      }, this.timeoutValue)
    }
  }

  disconnect() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }
  }

  dismiss() {
    // Clear timeout if it exists
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }

    // Add fade out animation
    this.element.style.transition = 'opacity 0.3s ease-in-out'
    this.element.style.opacity = '0'
    
    // Remove element after animation
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}