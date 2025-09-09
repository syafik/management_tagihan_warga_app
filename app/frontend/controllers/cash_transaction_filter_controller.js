import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "monthInput", "monthDisplay", "prevButton", "nextButton", "yearSelect"]

  connect() {
    console.log("Cash Transaction Filter controller connected")
    this.monthNames = {
      1: "Januari", 2: "Februari", 3: "Maret", 4: "April", 5: "Mei", 6: "Juni",
      7: "Juli", 8: "Agustus", 9: "September", 10: "Oktober", 11: "November", 12: "Desember"
    }
    this.updateButtonStates()
  }


  prevMonth() {
    const currentMonth = parseInt(this.monthInputTarget.value)
    const currentYear = this.hasYearSelectTarget ? parseInt(this.yearSelectTarget.value) : 2025
    
    let newMonth = currentMonth - 1
    let newYear = currentYear
    
    if (newMonth < 1) {
      newMonth = 12
      newYear = currentYear - 1
    }
    
    // Don't go before January 2025
    if (newYear < 2025 || (newYear === 2025 && newMonth < 1)) {
      return
    }
    
    this.updateMonthYear(newMonth, newYear)
    this.submitForm()
  }

  nextMonth() {
    const currentMonth = parseInt(this.monthInputTarget.value)
    const currentYear = this.hasYearSelectTarget ? parseInt(this.yearSelectTarget.value) : 2025
    
    let newMonth = currentMonth + 1
    let newYear = currentYear
    
    if (newMonth > 12) {
      newMonth = 1
      newYear = currentYear + 1
    }
    
    // Don't go after December 2050
    if (newYear > 2050 || (newYear === 2050 && newMonth > 12)) {
      return
    }
    
    this.updateMonthYear(newMonth, newYear)
    this.submitForm()
  }

  changeYear() {
    // Year select will submit automatically since it's a form field
    // We just need to make sure the month input is current
    const currentMonth = parseInt(this.monthInputTarget.value)
    
    // Update the month display
    if (this.hasMonthDisplayTarget) {
      this.monthDisplayTarget.textContent = this.monthNames[currentMonth]
    }
    
    this.updateButtonStates()
    this.submitForm()
  }

  changePIC() {
    this.submitForm()
  }

  submitForm() {
    if (this.hasFormTarget) {
      // Add a small delay to ensure the form inputs are updated before submission
      setTimeout(() => {
        this.formTarget.submit()
      }, 10)
    }
  }

  updateMonthYear(month, year) {
    this.monthInputTarget.value = month
    
    if (this.hasYearSelectTarget) {
      this.yearSelectTarget.value = year
    }
    
    if (this.hasMonthDisplayTarget) {
      this.monthDisplayTarget.textContent = this.monthNames[month]
    }
    
    this.updateButtonStates()
  }

  updateButtonStates() {
    const currentMonth = parseInt(this.monthInputTarget.value)
    const currentYear = this.hasYearSelectTarget ? parseInt(this.yearSelectTarget.value) : 2025
    
    // Update prev button state
    if (this.hasPrevButtonTarget) {
      const isAtMin = currentYear === 2025 && currentMonth === 1
      this.prevButtonTarget.disabled = isAtMin
      
      if (isAtMin) {
        this.prevButtonTarget.classList.add('opacity-50', 'cursor-not-allowed')
      } else {
        this.prevButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed')
      }
    }
    
    // Update next button state
    if (this.hasNextButtonTarget) {
      const isAtMax = currentYear === 2050 && currentMonth === 12
      this.nextButtonTarget.disabled = isAtMax
      
      if (isAtMax) {
        this.nextButtonTarget.classList.add('opacity-50', 'cursor-not-allowed')
      } else {
        this.nextButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed')
      }
    }
  }
}