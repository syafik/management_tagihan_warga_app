import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["monthDisplay"]
  static values = { 
    currentYear: Number,
    currentMonth: Number,
    reportType: String,
    startingYear: Number
  }

  connect() {
    this.currentYearValue = this.currentYearValue || new Date().getFullYear()
    this.currentMonthValue = this.currentMonthValue || new Date().getMonth() + 1
    this.startingYearValue = this.startingYearValue || 2025
  }

  navigateMonth(event) {
    event.preventDefault()
    const direction = event.target.dataset.direction
    
    if (direction === 'prev') {
      this.goToPreviousMonth()
    } else if (direction === 'next') {
      this.goToNextMonth()
    }
    
    this.updateMonthDisplay()
    this.redirectToReport()
  }

  goToPreviousMonth() {
    if (this.canGoPrevious) {
      if (this.currentMonthValue === 1) {
        this.currentMonthValue = 12
        this.currentYearValue -= 1
      } else {
        this.currentMonthValue -= 1
      }
    }
  }

  goToNextMonth() {
    if (this.canGoNext) {
      if (this.currentMonthValue === 12) {
        this.currentMonthValue = 1
        this.currentYearValue += 1
      } else {
        this.currentMonthValue += 1
      }
    }
  }

  updateMonthDisplay() {
    if (this.hasMonthDisplayTarget) {
      const monthNames = {
        1: 'Januari', 2: 'Februari', 3: 'Maret', 4: 'April',
        5: 'Mei', 6: 'Juni', 7: 'Juli', 8: 'Agustus',
        9: 'September', 10: 'Oktober', 11: 'November', 12: 'Desember'
      }
      this.monthDisplayTarget.textContent = `${monthNames[this.currentMonthValue]} ${this.currentYearValue}`
    }
  }

  redirectToReport() {
    const url = `/cash_transactions/show_report/${this.reportTypeValue}/${this.currentYearValue}/${this.currentMonthValue}`
    window.location.href = url
  }

  get canGoPrevious() {
    // Can't go before January of starting year
    return !(this.currentYearValue === this.startingYearValue && this.currentMonthValue === 1)
  }

  get canGoNext() {
    // Can't go after December 2050
    return !(this.currentYearValue === 2050 && this.currentMonthValue === 12)
  }

  get monthNames() {
    return {
      1: 'Januari', 2: 'Februari', 3: 'Maret', 4: 'April',
      5: 'Mei', 6: 'Juni', 7: 'Juli', 8: 'Agustus',
      9: 'September', 10: 'Oktober', 11: 'November', 12: 'Desember'
    }
  }
}