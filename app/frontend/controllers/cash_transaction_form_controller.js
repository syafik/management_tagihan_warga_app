import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "datePicker", "submitButton", "transactionType", "categorySelect"]
  static values = { 
    typeGroups: Object,
    allGroups: Object
  }
  
  connect() {
    console.log("Cash Transaction Form controller connected")
    
    // Define TYPE_GROUP mapping from Rails model
    this.typeGroupsValue = {
      "1": [1, 4, 6],  // DEBIT: IURAN WARGA, BAYAR KASBON, PEMASUKAN LAINNYA
      "2": [2, 3, 5]   // KREDIT: GAJI DAN UPAH, KASBON, LAIN-LAIN
    }
    
    // Define all groups with labels
    this.allGroupsValue = {
      "1": "IURAN WARGA",
      "2": "GAJI DAN UPAH", 
      "3": "KASBON",
      "4": "BAYAR KASBON",
      "5": "LAIN-LAIN",
      "6": "PEMASUKAN LAINNYA"
    }
    
    // Initialize category options based on current selection
    this.updateCategoryOptions()
  }

  initDatePicker(event) {
    const dateInput = event.target
    
    // Check if datepicker is already initialized
    if (dateInput.hasAttribute('data-datepicker-initialized')) {
      return
    }

    // Mark as initialized
    dateInput.setAttribute('data-datepicker-initialized', 'true')
    
    // Create a simple HTML5 date input fallback
    if (!dateInput.type || dateInput.type === 'text') {
      dateInput.type = 'date'
      
      // If there's a value, ensure it's in the correct format
      if (dateInput.value) {
        const date = new Date(dateInput.value)
        if (!isNaN(date.getTime())) {
          dateInput.value = date.toISOString().split('T')[0]
        }
      }
    }
    
    // If jQuery datepicker is available, use it
    if (typeof $ !== 'undefined' && $.fn.datepicker) {
      try {
        $(dateInput).datepicker({
          format: 'yyyy-mm-dd',
          todayHighlight: true,
          autoclose: true,
          orientation: 'bottom auto'
        })
      } catch (error) {
        console.warn('jQuery datepicker failed to initialize:', error)
      }
    }
  }

  // Handle transaction type change
  transactionTypeChanged() {
    console.log("Transaction type changed")
    this.updateCategoryOptions()
  }

  // Update category options based on selected transaction type
  updateCategoryOptions() {
    if (!this.hasTransactionTypeTarget || !this.hasCategorySelectTarget) {
      return
    }

    const selectedType = this.transactionTypeTarget.value
    console.log("Selected transaction type:", selectedType)
    
    // Clear current options
    this.categorySelectTarget.innerHTML = '<option value="">Pilih Kategori</option>'
    
    // Get allowed groups for this transaction type
    const allowedGroups = this.typeGroupsValue[selectedType] || []
    console.log("Allowed groups:", allowedGroups)
    
    // Add options for allowed groups
    allowedGroups.forEach(groupId => {
      const groupLabel = this.allGroupsValue[groupId.toString()]
      if (groupLabel) {
        const option = document.createElement('option')
        option.value = groupId
        option.textContent = groupLabel
        this.categorySelectTarget.appendChild(option)
      }
    })
  }

  handleSubmit(event) {
    console.log("Form submit handler called")
    
    // Validate form before submitting
    if (!this.validateForm()) {
      event.preventDefault()
      return false
    }
    
    this.disableSubmit()
    
    // Add loading state
    if (this.hasFormTarget) {
      this.formTarget.classList.add('opacity-75', 'pointer-events-none')
    }
    
    // Let the form submit naturally
  }

  disableSubmit(event) {
    if (this.hasSubmitButtonTarget) {
      const button = this.submitButtonTarget
      button.disabled = true
      button.classList.add('opacity-50', 'cursor-not-allowed')
      
      const originalText = button.textContent
      button.textContent = button.textContent.includes('Simpan') ? 'Menyimpan...' : 'Memperbarui...'
      
      // Re-enable after 3 seconds to prevent permanent disable
      setTimeout(() => {
        button.disabled = false
        button.classList.remove('opacity-50', 'cursor-not-allowed')
        button.textContent = originalText
        
        if (this.hasFormTarget) {
          this.formTarget.classList.remove('opacity-75', 'pointer-events-none')
        }
      }, 3000)
    }
  }

  formatCurrency(event) {
    const input = event.target
    let value = input.value.replace(/[^0-9]/g, '')
    
    if (value) {
      // Format as currency
      const formatted = new Intl.NumberFormat('id-ID').format(value)
      input.value = formatted
    }
  }

  validateForm() {
    let isValid = true
    const requiredFields = this.formTarget.querySelectorAll('[required]')
    
    requiredFields.forEach(field => {
      if (!field.value.trim()) {
        field.classList.add('border-red-300', 'focus:border-red-500', 'focus:ring-red-500')
        field.classList.remove('border-gray-300', 'focus:border-blue-500', 'focus:ring-blue-500')
        isValid = false
      } else {
        field.classList.remove('border-red-300', 'focus:border-red-500', 'focus:ring-red-500')
        field.classList.add('border-gray-300', 'focus:border-blue-500', 'focus:ring-blue-500')
      }
    })
    
    return isValid
  }
}