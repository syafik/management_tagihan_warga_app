import { Controller } from "@hotwired/stimulus"

// Example Stimulus controller
export default class extends Controller {
  connect() {
    this.element.textContent = "Hello Stimulus!"
  }
}