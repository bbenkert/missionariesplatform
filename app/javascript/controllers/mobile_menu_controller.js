import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="mobile-menu"
export default class extends Controller {
  static targets = ["menu", "openIcon", "closeIcon"]

  connect() {
    // Initialize menu state
    this.menuOpen = false
  }

  toggle() {
    this.menuOpen = !this.menuOpen
    
    if (this.menuOpen) {
      this.showMenu()
    } else {
      this.hideMenu()
    }
  }

  showMenu() {
    // Show mobile menu
    const menu = document.querySelector('.mobile-menu')
    const menuIcon = document.querySelector('.menu-icon')
    const closeIcon = document.querySelector('.close-icon')
    
    if (menu) menu.classList.remove('hidden')
    if (menuIcon) menuIcon.classList.add('hidden')
    if (closeIcon) closeIcon.classList.remove('hidden')
  }

  hideMenu() {
    // Hide mobile menu
    const menu = document.querySelector('.mobile-menu')
    const menuIcon = document.querySelector('.menu-icon')
    const closeIcon = document.querySelector('.close-icon')
    
    if (menu) menu.classList.add('hidden')
    if (menuIcon) menuIcon.classList.remove('hidden')
    if (closeIcon) closeIcon.classList.add('hidden')
  }

  // Hide menu when clicking outside
  clickOutside(event) {
    const menu = document.querySelector('.mobile-menu')
    const button = document.querySelector('.mobile-menu-button')
    
    if (this.menuOpen && menu && button && 
        !menu.contains(event.target) && 
        !button.contains(event.target)) {
      this.hideMenu()
      this.menuOpen = false
    }
  }

  // Auto-hide on window resize to desktop
  handleResize() {
    if (window.innerWidth >= 640 && this.menuOpen) { // sm breakpoint
      this.hideMenu()
      this.menuOpen = false
    }
  }
}
