import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["rooms", "template"]

  add() {
    const index = this.roomsTarget.querySelectorAll("[data-repeatable-room-target='room']").length
    const template = this.templateTarget.innerHTML.replace(/__INDEX__/g, index)
    const templateElement = document.createElement("template")
    templateElement.innerHTML = template.trim()

    this.roomsTarget.appendChild(templateElement.content)
  }

  remove(event) {
    const room = event.currentTarget.closest("[data-repeatable-room-target='room']")
    if (!room) return

    const remainingRooms = this.roomsTarget.querySelectorAll("[data-repeatable-room-target='room']").length
    if (remainingRooms <= 1) return

    room.remove()
  }
}
