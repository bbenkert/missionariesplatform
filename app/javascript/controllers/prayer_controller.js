import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "count"]

  pray(event) {
    event.preventDefault()
    
    const form = event.target.closest('form')
    const url = form.action
    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content')

    // Disable button during request
    const button = this.buttonTarget
    const originalContent = button.innerHTML
    button.disabled = true
    button.innerHTML = `
      <svg class="h-4 w-4 animate-spin" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
    `

    fetch(url, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }
    })
    .then(response => {
      if (response.ok) {
        return response.json()
      }
      throw new Error('Network response was not ok')
    })
    .then(data => {
      // Update the prayer count
      if (this.hasCountTarget) {
        const currentCount = parseInt(this.countTarget.textContent.split(' ')[0])
        this.countTarget.textContent = `${currentCount + 1} prayers`
      }

      // Show success feedback
      button.innerHTML = `
        <svg class="h-4 w-4 text-green-600" fill="currentColor" viewBox="0 0 24 24">
          <path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
        </svg>
      `
      button.classList.add('text-green-600')

      // Reset button after 2 seconds
      setTimeout(() => {
        button.innerHTML = originalContent
        button.disabled = false
        button.classList.remove('text-green-600')
      }, 2000)
    })
    .catch(error => {
      console.error('Error:', error)
      button.innerHTML = originalContent
      button.disabled = false
      
      // Show error feedback
      button.classList.add('text-red-600')
      setTimeout(() => {
        button.classList.remove('text-red-600')
      }, 2000)
    })
  }
}
