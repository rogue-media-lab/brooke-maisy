import { Controller } from "@hotwired/stimulus"
import SignaturePad from "signature_pad"

export default class extends Controller {
  static targets = [ "canvas", "typedName", "agreeCheckbox", "submitBtn", "clearBtn", "hint" ]

  connect() {
    this.signaturePad = new SignaturePad(this.canvasTarget, {
      penColor: "rgb(0, 0, 0)",
      minWidth: 0.5,
      maxWidth: 2.5
    })

    // Resize canvas to its display size for crisp rendering
    this.resizeCanvas()

    // Enable submit only when signature exists + name typed + agreed
    this.updateSubmitState()
    this.signaturePad.addEventListener("endStroke", () => this.updateSubmitState())
    this.typedNameTarget.addEventListener("input", () => this.updateSubmitState())
    this.agreeCheckboxTarget.addEventListener("change", () => this.updateSubmitState())
  }

  resizeCanvas() {
    const ratio = Math.max(window.devicePixelRatio || 1, 1)
    this.canvasTarget.width = this.canvasTarget.offsetWidth * ratio
    this.canvasTarget.height = this.canvasTarget.offsetHeight * ratio
    this.canvasTarget.getContext("2d").scale(ratio, ratio)
    this.signaturePad.clear()
  }

  clear() {
    this.signaturePad.clear()
    this.updateSubmitState()
  }

  updateSubmitState() {
    const hasSignature = !this.signaturePad.isEmpty()
    const hasName = this.typedNameTarget.value.trim().length > 0
    const hasAgreed = this.agreeCheckboxTarget.checked

    if (hasSignature && hasName && hasAgreed) {
      this.submitBtnTarget.disabled = false
      this.submitBtnTarget.classList.remove("opacity-50", "cursor-not-allowed")
      this.hintTarget.classList.add("hidden")
    } else {
      this.submitBtnTarget.disabled = true
      this.submitBtnTarget.classList.add("opacity-50", "cursor-not-allowed")
      this.hintTarget.classList.remove("hidden")
    }
  }

  submit(event) {
    event.preventDefault()

    if (this.signaturePad.isEmpty()) {
      this.hintTarget.textContent = "Please draw your signature above."
      this.hintTarget.classList.remove("hidden")
      return
    }

    // Capture signature as base64 PNG
    const signatureData = this.signaturePad.toDataURL("image/png")

    // Populate hidden fields
    const form = this.submitBtnTarget.closest("form")
    const signatureField = form.querySelector("input[name='signature[signature_data]']")
    const nameField = form.querySelector("input[name='signature[signed_name]']")

    if (signatureField) signatureField.value = signatureData
    if (nameField) nameField.value = this.typedNameTarget.value.trim()

    // Submit the form normally (non-Turbo)
    form.requestSubmit()
  }
}
