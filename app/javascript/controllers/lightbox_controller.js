import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "image"]

  connect() {
    this.boundKeydown = this.keydown.bind(this)
    document.addEventListener("keydown", this.boundKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown)
  }

  open(event) {
    const img = event.currentTarget.querySelector("img")
    if (!img) return

    this.imageTarget.src = img.src
    this.imageTarget.alt = img.alt || ""
    this.overlayTarget.classList.remove("hidden")
    this.overlayTarget.classList.add("flex")
    document.body.style.overflow = "hidden"
  }

  close() {
    this.overlayTarget.classList.add("hidden")
    this.overlayTarget.classList.remove("flex")
    this.imageTarget.src = ""
    document.body.style.overflow = ""
  }

  clickOutside(event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }

  keydown(event) {
    if (event.key === "Escape" && !this.overlayTarget.classList.contains("hidden")) {
      this.close()
    }
  }
}
