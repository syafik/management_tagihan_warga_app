import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "title", "message", "confirmButton", "cancelButton"]
  static values = { 
    title: String,
    message: String,
    confirmText: String,
    cancelText: String,
    confirmClass: String
  }

  connect() {
    console.log("Confirm Modal controller connected")
  }

  show(event) {
    event.preventDefault()
    
    const button = event.currentTarget
    const form = button.closest('form')
    
    // Get confirmation data from the button
    this.form = form
    this.titleValue = button.dataset.confirmTitle || "Konfirmasi"
    this.messageValue = button.dataset.confirmMessage || "Apakah Anda yakin?"
    this.confirmTextValue = button.dataset.confirmText || "Ya, Hapus"
    this.cancelTextValue = button.dataset.cancelText || "Batal"
    this.confirmClassValue = button.dataset.confirmClass || "bg-red-600 hover:bg-red-700"

    // Update modal content
    this.titleTarget.textContent = this.titleValue
    this.messageTarget.textContent = this.messageValue
    this.confirmButtonTarget.textContent = this.confirmTextValue
    this.cancelButtonTarget.textContent = this.cancelTextValue
    
    // Update confirm button styling
    this.confirmButtonTarget.className = `px-4 py-2 text-white font-medium rounded-md focus:outline-none focus:ring-2 focus:ring-offset-2 transition-colors duration-200 ${this.confirmClassValue}`
    
    // Show modal
    this.modalTarget.classList.remove('hidden')
    document.body.classList.add('overflow-hidden')
  }

  hide() {
    this.modalTarget.classList.add('hidden')
    document.body.classList.remove('overflow-hidden')
    this.form = null
  }

  confirm() {
    if (this.form) {
      // Disable the confirm button to prevent double submission
      this.confirmButtonTarget.disabled = true
      this.confirmButtonTarget.textContent = "Menghapus..."
      
      // Submit the form
      this.form.submit()
    }
    this.hide()
  }

  cancel() {
    this.hide()
  }

  // Close modal when clicking outside
  clickOutside(event) {
    if (event.target === this.modalTarget) {
      this.cancel()
    }
  }

  // Handle escape key
  keydown(event) {
    if (event.key === 'Escape') {
      this.cancel()
    }
  }
}