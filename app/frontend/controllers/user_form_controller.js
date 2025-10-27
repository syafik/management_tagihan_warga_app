import { Controller } from "@hotwired/stimulus"
import Choices from 'choices.js'

export default class extends Controller {
  static targets = ["roleSelect", "addressBox", "picBox", "addressSelect", "form"]

  connect() {
    // Add form submit handler to clean up empty values
    if (this.element.querySelector('form')) {
      this.element.querySelector('form').addEventListener('submit', (e) => {
        this.cleanupFormData(e)
      })
    }
    // Initialize Choices.js for role select
    if (this.hasRoleSelectTarget) {
      this.roleChoice = new Choices(this.roleSelectTarget, {
        searchEnabled: false,
        itemSelectText: '',
        shouldSort: false
      })

      // Add w-full class manually to container
      this.roleSelectTarget.parentElement.classList.add('w-full')
    }

    // Initialize Choices.js for address multi-select
    if (this.hasAddressSelectTarget) {
      // First, remove any empty options from the select
      Array.from(this.addressSelectTarget.options).forEach(option => {
        if (option.value === '') {
          option.remove()
        }
      })

      const isMobile = window.innerWidth < 768

      this.addressChoice = new Choices(this.addressSelectTarget, {
        removeItemButton: true,
        searchEnabled: true,
        searchPlaceholderValue: 'Cari blok rumah...',
        noResultsText: 'Tidak ada hasil ditemukan',
        noChoicesText: 'Tidak ada pilihan tersisa',
        itemSelectText: 'Tekan untuk memilih',
        maxItemText: (maxItemCount) => {
          return `Hanya ${maxItemCount} nilai yang dapat ditambahkan`
        },
        placeholder: false,
        shouldSort: false,
        removeItemButton: true,
        duplicateItemsAllowed: false,
        // Custom item rendering for selected items (badges)
        callbackOnCreateTemplates: (template) => {
          return {
            item: ({ classNames }, data) => {
              return template(`
                <div class="${classNames.item} ${data.highlighted ? classNames.highlightedState : classNames.itemSelectable} ${data.placeholder ? classNames.placeholder : ''} inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800 m-0.5" data-item data-id="${data.id}" data-value="${data.value}" ${data.active ? 'aria-selected="true"' : ''} ${data.disabled ? 'aria-disabled="true"' : ''}>
                  ${data.label}
                  <button type="button" class="${classNames.button} ml-1.5 inline-flex items-center justify-center w-4 h-4 text-indigo-600 hover:text-indigo-800 focus:outline-none" data-button aria-label="Remove item: '${data.value}'">
                    <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                      <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"/>
                    </svg>
                  </button>
                </div>
              `)
            },
            choice: ({ classNames }, data) => {
              const isSelected = data.selected
              const checkmark = isSelected
                ? `<svg class="w-4 h-4 text-indigo-600 mr-2 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/></svg>`
                : `<svg class="w-4 h-4 text-gray-300 mr-2 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 20 20"><circle cx="10" cy="10" r="8" stroke-width="2"/></svg>`

              return template(`
                <div class="${classNames.item} ${classNames.itemChoice} ${data.disabled ? classNames.itemDisabled : classNames.itemSelectable} flex items-center justify-between w-full py-2 px-3 hover:bg-indigo-50" data-choice ${data.disabled ? 'data-choice-disabled aria-disabled="true"' : 'data-choice-selectable'} data-id="${data.id}" data-value="${data.value}" ${data.groupId > 0 ? 'role="treeitem"' : 'role="option"'}>
                  <div class="flex items-center flex-1">
                    ${checkmark}
                    <span class="${isSelected ? 'font-semibold text-indigo-900' : 'font-normal text-gray-900'}">${data.label}</span>
                  </div>
                  ${isSelected ? '<span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800 ml-2">Dipilih</span>' : ''}
                </div>
              `)
            }
          }
        }
      })

      // Add w-full class manually to container
      const choicesContainer = this.addressSelectTarget.closest('.choices')
      if (choicesContainer) {
        choicesContainer.classList.add('w-full')
      }

      // Mobile backdrop for better UX
      if (isMobile) {
        this.addressSelectTarget.addEventListener('showDropdown', () => {
          this.addMobileBackdrop()
        })

        this.addressSelectTarget.addEventListener('hideDropdown', () => {
          this.removeMobileBackdrop()
        })
      }
    }

    this.toggleFields()
  }

  addMobileBackdrop() {
    if (!document.querySelector('.choices-backdrop')) {
      const backdrop = document.createElement('div')
      backdrop.className = 'choices-backdrop fixed inset-0 bg-black bg-opacity-50 z-[9998]'
      backdrop.addEventListener('click', () => {
        if (this.addressChoice) {
          this.addressChoice.hideDropdown()
        }
      })
      document.body.appendChild(backdrop)
    }
  }

  removeMobileBackdrop() {
    const backdrop = document.querySelector('.choices-backdrop')
    if (backdrop) {
      backdrop.remove()
    }
  }

  disconnect() {
    // Clean up backdrop
    this.removeMobileBackdrop()

    // Destroy Choices instances
    if (this.roleChoice) {
      this.roleChoice.destroy()
    }
    if (this.addressChoice) {
      this.addressChoice.destroy()
    }
  }

  roleChanged() {
    this.toggleFields()
  }

  toggleFields() {
    const roleValue = this.roleSelectTarget.value

    if (roleValue === '3') { // Security role
      this.addressBoxTarget.classList.add('hidden')
      if (this.addressChoice) {
        this.addressChoice.removeActiveItems()
      }
      this.picBoxTarget.classList.remove('hidden')
      this.picBoxTarget.querySelector('input').value = ''
    } else {
      this.addressBoxTarget.classList.remove('hidden')
      this.picBoxTarget.classList.add('hidden')
    }
  }

  cleanupFormData(event) {
    // Remove empty values from address_ids select
    if (this.hasAddressSelectTarget) {
      const select = this.addressSelectTarget
      const options = Array.from(select.options)

      options.forEach(option => {
        if (option.value === '' && option.selected) {
          option.selected = false
        }
      })
    }
  }
}
