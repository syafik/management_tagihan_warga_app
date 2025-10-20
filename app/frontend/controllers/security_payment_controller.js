import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "form",
    "arrearsCheckbox",
    "unpaidCheckbox",
    "futureCheckbox",
    "paymentType",
    "totalAmount",
    "selectedInfo",
    "submitButton"
  ]

  connect() {
    console.log("Security payment controller connected")
    this.updateTotal()
  }

  updateTotal() {
    let total = 0
    let selectedItems = []

    // Check arrears
    if (this.hasArrearsCheckboxTarget && this.arrearsCheckboxTarget.checked) {
      const amount = parseInt(this.arrearsCheckboxTarget.value) || 0
      total += amount
      selectedItems.push("Tunggakan Lama")
    }

    // Check unpaid months
    const unpaidChecked = this.unpaidCheckboxTargets.filter(cb => cb.checked)
    unpaidChecked.forEach(checkbox => {
      const amount = parseFloat(checkbox.dataset.amount) || 0
      total += amount
    })
    if (unpaidChecked.length > 0) {
      selectedItems.push(`${unpaidChecked.length} bulan belum bayar`)
    }

    // Check future months
    const futureChecked = this.futureCheckboxTargets.filter(cb => cb.checked)
    futureChecked.forEach(checkbox => {
      const amount = parseFloat(checkbox.dataset.amount) || 0
      total += amount
    })
    if (futureChecked.length > 0) {
      selectedItems.push(`${futureChecked.length} bulan bayar di muka`)
    }

    // Update display
    this.totalAmountTarget.textContent = `Rp ${this.formatCurrency(total)}`

    if (selectedItems.length > 0) {
      this.selectedInfoTarget.textContent = selectedItems.join(" + ")
      this.submitButtonTarget.disabled = false
    } else {
      this.selectedInfoTarget.textContent = "Pilih item pembayaran"
      this.submitButtonTarget.disabled = true
    }
  }

  selectAllUnpaid() {
    this.unpaidCheckboxTargets.forEach(checkbox => {
      checkbox.checked = true
    })
    this.updateTotal()
  }

  selectAllFuture() {
    this.futureCheckboxTargets.forEach(checkbox => {
      checkbox.checked = true
    })
    this.updateTotal()
  }

  payAllArrears() {
    // Select arrears and all unpaid months
    if (this.hasArrearsCheckboxTarget) {
      this.arrearsCheckboxTarget.checked = true
    }

    this.unpaidCheckboxTargets.forEach(checkbox => {
      checkbox.checked = true
    })

    this.updateTotal()
  }

  payAll() {
    // Select everything
    if (this.hasArrearsCheckboxTarget) {
      this.arrearsCheckboxTarget.checked = true
    }

    this.unpaidCheckboxTargets.forEach(checkbox => {
      checkbox.checked = true
    })

    this.futureCheckboxTargets.forEach(checkbox => {
      checkbox.checked = true
    })

    this.updateTotal()
  }

  clearAll() {
    // Uncheck everything
    if (this.hasArrearsCheckboxTarget) {
      this.arrearsCheckboxTarget.checked = false
    }

    this.unpaidCheckboxTargets.forEach(checkbox => {
      checkbox.checked = false
    })

    this.futureCheckboxTargets.forEach(checkbox => {
      checkbox.checked = false
    })

    this.updateTotal()
  }

  formatCurrency(amount) {
    return amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".")
  }
}
