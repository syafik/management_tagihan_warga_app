import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dateInput"]

  connect() {
    console.log("Import Form controller connected")
    this.initializeDateInput()
  }

  initializeDateInput() {
    if (this.hasDateInputTarget) {
      // Set up a modern HTML5 date input
      this.dateInputTarget.type = "date"
      
      // Set default to today if empty
      if (!this.dateInputTarget.value) {
        const today = new Date()
        const formattedDate = today.toISOString().split('T')[0]
        this.dateInputTarget.value = formattedDate
      }
    }
  }
}