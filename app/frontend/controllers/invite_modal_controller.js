import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "form"]

  show() {
    if (this.hasModalTarget) {
      this.modalTarget.classList.remove("hidden")
    }
  }

  hide() {
    if (this.hasModalTarget) {
      this.modalTarget.classList.add("hidden")
    }
    if (this.hasFormTarget) {
      this.formTarget.reset()
    }
  }

  hideOnBackdrop(event) {
    if (this.hasModalTarget && event.target === this.modalTarget) {
      this.hide()
    }
  }
}