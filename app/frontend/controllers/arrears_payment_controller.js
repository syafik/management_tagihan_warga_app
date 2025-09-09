import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["monthsField", "rateField", "totalField"]

  connect() {
    console.log("Arrears payment controller connected")
    this.updateTotal()
  }

  updateTotal() {
    const months = parseInt(this.monthsFieldTarget.value || 0)
    const rate = parseInt(this.rateFieldTarget.value || 0)
    const total = months * rate
    
    console.log(`Calculating: ${months} months × ${rate} = ${total}`)
    
    this.totalFieldTarget.value = total
  }
}