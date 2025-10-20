import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["radio", "cashLabel", "transferLabel", "cashIcon", "transferIcon"]

  connect() {
    // Set initial state
    this.updateSelection()
  }

  updateSelection() {
    const selectedRadio = this.radioTargets.find(radio => radio.checked)

    if (!selectedRadio) return

    const isCash = selectedRadio.value === "1"

    // Update Cash label
    if (isCash) {
      this.cashLabelTarget.classList.add('border-indigo-600', 'bg-indigo-50')
      this.cashLabelTarget.classList.remove('border-gray-300')
      this.cashIconTarget.classList.add('text-indigo-600')
      this.cashIconTarget.classList.remove('text-gray-600')
    } else {
      this.cashLabelTarget.classList.remove('border-indigo-600', 'bg-indigo-50')
      this.cashLabelTarget.classList.add('border-gray-300')
      this.cashIconTarget.classList.remove('text-indigo-600')
      this.cashIconTarget.classList.add('text-gray-600')
    }

    // Update Transfer label
    if (!isCash) {
      this.transferLabelTarget.classList.add('border-indigo-600', 'bg-indigo-50')
      this.transferLabelTarget.classList.remove('border-gray-300')
      this.transferIconTarget.classList.add('text-indigo-600')
      this.transferIconTarget.classList.remove('text-gray-600')
    } else {
      this.transferLabelTarget.classList.remove('border-indigo-600', 'bg-indigo-50')
      this.transferLabelTarget.classList.add('border-gray-300')
      this.transferIconTarget.classList.remove('text-indigo-600')
      this.transferIconTarget.classList.add('text-gray-600')
    }
  }
}
