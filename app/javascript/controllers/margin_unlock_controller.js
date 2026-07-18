import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "locked", "unlockButton" ]

  connect() {
    if (sessionStorage.getItem("marginsUnlocked") === "true") {
      this.unlock()
    }
  }

  prompt(event) {
    event.preventDefault()
    const pin = prompt("Enter PIN to view margins:")
    if (pin === null) return

    const expectedPin = document.querySelector('meta[name="margin-pin"]')?.content
    if (pin === expectedPin) {
      sessionStorage.setItem("marginsUnlocked", "true")
      this.unlock()
    } else {
      alert("Incorrect PIN.")
    }
  }

  unlock() {
    this.lockedTargets.forEach(el => el.classList.remove("hidden"))
    this.unlockButtonTarget.classList.add("hidden")
  }

  lock() {
    sessionStorage.removeItem("marginsUnlocked")
    this.lockedTargets.forEach(el => el.classList.add("hidden"))
    this.unlockButtonTarget.classList.remove("hidden")
  }
}
