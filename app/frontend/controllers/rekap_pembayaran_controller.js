import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["monthInput", "yearInput", "monthDisplay", "form"]
  static values = {
    monthNames: Object
  }

  connect() {
    // Month names mapping (Indonesian)
    this.monthNamesValue = {
      1: "Januari",
      2: "Februari",
      3: "Maret",
      4: "April",
      5: "Mei",
      6: "Juni",
      7: "Juli",
      8: "Agustus",
      9: "September",
      10: "Oktober",
      11: "November",
      12: "Desember"
    }
  }

  prevMonth(event) {
    event.preventDefault()
    let month = parseInt(this.monthInputTarget.value)
    let year = parseInt(this.yearInputTarget.value)

    month--
    if (month < 1) {
      month = 12
      year--
    }

    this.monthInputTarget.value = month
    this.yearInputTarget.value = year
    this.formTarget.submit()
  }

  nextMonth(event) {
    event.preventDefault()
    let month = parseInt(this.monthInputTarget.value)
    let year = parseInt(this.yearInputTarget.value)

    month++
    if (month > 12) {
      month = 1
      year++
    }

    this.monthInputTarget.value = month
    this.yearInputTarget.value = year
    this.formTarget.submit()
  }
}
