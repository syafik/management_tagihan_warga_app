import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "showText", "hideText"]

  toggle() {
    const visible = this.inputTarget.type === "text"

    this.inputTarget.type = visible ? "password" : "text"
    this.showTextTarget.classList.toggle("hidden", !visible)
    this.hideTextTarget.classList.toggle("hidden", visible)
  }
}
