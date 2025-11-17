import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["totalAmount", "itemCount", "totalAmountBottom", "itemCountBottom", "arrearsCheckbox", "unpaidCheckbox", "futureCheckbox", "nextYearCheckbox", "submitButton", "form"]

  connect() {
    this.updateTotal()

    // Debug: Log form submit
    if (this.hasFormTarget) {
      this.formTarget.addEventListener('submit', (e) => {
        console.log('=== FORM SUBMIT DEBUG ===')
        const formData = new FormData(this.formTarget)
        console.log('pay_arrears values:', formData.getAll('pay_arrears[]'))
        console.log('All checked arrears checkboxes:', this.arrearsCheckboxTargets.filter(cb => cb.checked).map(cb => cb.value))
      })
    }
  }

  updateTotal() {
    let total = 0
    let count = 0

    // Count all checked checkboxes and sum amounts
    const allCheckboxes = [
      ...this.arrearsCheckboxTargets,
      ...this.unpaidCheckboxTargets,
      ...(this.hasFutureCheckboxTarget ? this.futureCheckboxTargets : []),
      ...(this.hasNextYearCheckboxTarget ? this.nextYearCheckboxTargets : [])
    ]

    allCheckboxes.forEach(checkbox => {
      if (checkbox.checked) {
        const amount = parseInt(checkbox.dataset.amount || 0)
        total += amount
        count++
      }
    })

    // Update display
    this.updateTotalDisplay(total, count)

    // Enable/disable submit button
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = count === 0
      if (count === 0) {
        this.submitButtonTarget.classList.add('opacity-50', 'cursor-not-allowed')
      } else {
        this.submitButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed')
      }
    }
  }

  updateTotalDisplay(total, count) {
    // Format currency for display
    const formatted = new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0
    }).format(total)

    // Update floating summary (top)
    if (this.hasTotalAmountTarget) {
      this.totalAmountTarget.textContent = formatted
    }

    if (this.hasItemCountTarget) {
      this.itemCountTarget.textContent = `${count} item`
    }

    // Update bottom total
    if (this.hasTotalAmountBottomTarget) {
      this.totalAmountBottomTarget.textContent = formatted
    }

    if (this.hasItemCountBottomTarget) {
      this.itemCountBottomTarget.textContent = `${count} item`
    }
  }

  selectAllArrears(event) {
    event.preventDefault()
    this.arrearsCheckboxTargets.forEach(checkbox => {
      checkbox.checked = true
      // Trigger visual update for peer-checked styles
      checkbox.dispatchEvent(new Event('change', { bubbles: true }))
    })
    this.updateTotal()
  }

  selectAllUnpaid(event) {
    event.preventDefault()
    this.unpaidCheckboxTargets.forEach(checkbox => {
      checkbox.checked = true
      checkbox.dispatchEvent(new Event('change', { bubbles: true }))
    })
    this.updateTotal()
  }

  selectAllFuture(event) {
    event.preventDefault()
    if (this.hasFutureCheckboxTarget) {
      this.futureCheckboxTargets.forEach(checkbox => {
        checkbox.checked = true
        checkbox.dispatchEvent(new Event('change', { bubbles: true }))
      })
    }
    this.updateTotal()
  }

  selectAllNextYear(event) {
    event.preventDefault()
    if (this.hasNextYearCheckboxTarget) {
      this.nextYearCheckboxTargets.forEach(checkbox => {
        checkbox.checked = true
        checkbox.dispatchEvent(new Event('change', { bubbles: true }))
      })
    }
    this.updateTotal()
  }

  resetSelection(event) {
    event.preventDefault()
    const allCheckboxes = [
      ...this.arrearsCheckboxTargets,
      ...this.unpaidCheckboxTargets,
      ...(this.hasFutureCheckboxTarget ? this.futureCheckboxTargets : []),
      ...(this.hasNextYearCheckboxTarget ? this.nextYearCheckboxTargets : [])
    ]

    allCheckboxes.forEach(checkbox => {
      checkbox.checked = false
      checkbox.dispatchEvent(new Event('change', { bubbles: true }))
    })
    this.updateTotal()
  }

  toggleCard(event) {
    const checkbox = event.target
    const card = checkbox.closest('.month-card')
    const circle = card.querySelector('.checkmark-circle')
    const icon = card.querySelector('.checkmark-icon')

    if (checkbox.checked) {
      // Selected state
      if (card.classList.contains('border-red-300')) {
        // Red/arrears months
        card.classList.remove('border-red-300', 'bg-red-50')
        card.classList.add('border-red-500', 'bg-red-100')
        circle.classList.remove('border-red-400')
        circle.classList.add('bg-red-500', 'border-red-500')
      } else if (card.classList.contains('border-orange-200')) {
        // Orange/unpaid months
        card.classList.remove('border-orange-200', 'bg-orange-50')
        card.classList.add('border-orange-500', 'bg-orange-100')
        circle.classList.remove('border-orange-400')
        circle.classList.add('bg-orange-500', 'border-orange-500')
      } else if (card.classList.contains('border-blue-200')) {
        // Blue/current year future months
        card.classList.remove('border-blue-200', 'bg-blue-50')
        card.classList.add('border-blue-500', 'bg-blue-100')
        circle.classList.remove('border-blue-400')
        circle.classList.add('bg-blue-500', 'border-blue-500')
      } else if (card.classList.contains('border-indigo-200')) {
        // Indigo/next year months
        card.classList.remove('border-indigo-200', 'bg-indigo-50')
        card.classList.add('border-indigo-500', 'bg-indigo-100')
        circle.classList.remove('border-indigo-400')
        circle.classList.add('bg-indigo-500', 'border-indigo-500')
      }
      icon.classList.remove('opacity-0')
      icon.classList.add('opacity-100')
    } else {
      // Unselected state
      if (card.classList.contains('border-red-500')) {
        // Red/arrears months
        card.classList.remove('border-red-500', 'bg-red-100')
        card.classList.add('border-red-300', 'bg-red-50')
        circle.classList.remove('bg-red-500', 'border-red-500')
        circle.classList.add('border-red-400')
      } else if (card.classList.contains('border-orange-500')) {
        // Orange/unpaid months
        card.classList.remove('border-orange-500', 'bg-orange-100')
        card.classList.add('border-orange-200', 'bg-orange-50')
        circle.classList.remove('bg-orange-500', 'border-orange-500')
        circle.classList.add('border-orange-400')
      } else if (card.classList.contains('border-blue-500')) {
        // Blue/current year future months
        card.classList.remove('border-blue-500', 'bg-blue-100')
        card.classList.add('border-blue-200', 'bg-blue-50')
        circle.classList.remove('bg-blue-500', 'border-blue-500')
        circle.classList.add('border-blue-400')
      } else if (card.classList.contains('border-indigo-500')) {
        // Indigo/next year months
        card.classList.remove('border-indigo-500', 'bg-indigo-100')
        card.classList.add('border-indigo-200', 'bg-indigo-50')
        circle.classList.remove('bg-indigo-500', 'border-indigo-500')
        circle.classList.add('border-indigo-400')
      }
      icon.classList.remove('opacity-100')
      icon.classList.add('opacity-0')
    }
  }

  togglePaymentMethod(event) {
    const radio = event.target
    const allCards = document.querySelectorAll('.payment-method-card')

    // Reset all cards
    allCards.forEach(card => {
      const icon = card.querySelector('.payment-icon')
      const svg = icon.querySelector('svg')
      const cardRadio = card.querySelector('.payment-radio')

      if (cardRadio === radio) {
        // Selected card
        if (radio.value === '1') {
          // Cash selected
          card.classList.remove('border-gray-200')
          card.classList.add('border-green-200', 'bg-green-50')
          icon.classList.remove('bg-green-100')
          icon.classList.add('bg-green-500')
          svg.classList.remove('text-green-600')
          svg.classList.add('text-white')
        } else {
          // Transfer selected
          card.classList.remove('border-gray-200')
          card.classList.add('border-blue-200', 'bg-blue-50')
          icon.classList.remove('bg-blue-100')
          icon.classList.add('bg-blue-500')
          svg.classList.remove('text-blue-600')
          svg.classList.add('text-white')
        }
      } else {
        // Unselected card
        const unselectedRadio = card.querySelector('.payment-radio')
        if (unselectedRadio.value === '1') {
          // Cash unselected
          card.classList.remove('border-green-200', 'bg-green-50')
          card.classList.add('border-gray-200')
          icon.classList.remove('bg-green-500')
          icon.classList.add('bg-green-100')
          svg.classList.remove('text-white')
          svg.classList.add('text-green-600')
        } else {
          // Transfer unselected
          card.classList.remove('border-blue-200', 'bg-blue-50')
          card.classList.add('border-gray-200')
          icon.classList.remove('bg-blue-500')
          icon.classList.add('bg-blue-100')
          svg.classList.remove('text-white')
          svg.classList.add('text-blue-600')
        }
      }
    })
  }
}
