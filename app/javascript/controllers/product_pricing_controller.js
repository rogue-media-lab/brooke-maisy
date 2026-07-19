import { Controller } from "@hotwired/stimulus"

// Manages dynamic price-point rows in the product admin form.
// Standard sizes are pre-rendered server-side with read-only width/height;
// this controller handles "Add custom size" rows (editable width/height/cost)
// and removing any row.
export default class extends Controller {
  static targets = [ "container" ]

  addPoint() {
    const row = this._buildRow({})
    this.containerTarget.appendChild(row)
  }

  removePoint(event) {
    const row = event.target.closest("[data-price-point]")
    if (row) row.remove()
  }

  // private

  _buildRow({ width = "", height = "", cost = "" }) {
    const row = document.createElement("div")
    row.setAttribute("data-price-point", "")
    row.className = "grid grid-cols-12 gap-3 items-center"

    const widthCell = this._buildCell("Width", "width", width, "col-span-3")
    const heightCell = this._buildCell("Height", "height", height, "col-span-3")
    const costCell = this._buildCostCell(cost, "col-span-4")
    const removeCell = this._buildRemoveCell()

    row.appendChild(widthCell)
    row.appendChild(heightCell)
    row.appendChild(costCell)
    row.appendChild(removeCell)
    return row
  }

  _buildCell(label, name, value, wrapperClass) {
    const wrap = document.createElement("div")
    wrap.className = wrapperClass

    const labelEl = document.createElement("label")
    labelEl.className = "block text-xs font-medium text-gray-500 mb-1"
    labelEl.textContent = label
    wrap.appendChild(labelEl)

    const input = document.createElement("input")
    input.type = "number"
    input.name = `product[pricing][price_points][][${name}]`
    input.value = value
    input.className = "w-full rounded-lg border-gray-300 focus:border-theme-500 focus:ring-theme-500"
    wrap.appendChild(input)

    return wrap
  }

  _buildCostCell(value, wrapperClass) {
    const wrap = document.createElement("div")
    wrap.className = wrapperClass

    const labelEl = document.createElement("label")
    labelEl.className = "block text-xs font-medium text-gray-500 mb-1"
    labelEl.textContent = "Cost"
    wrap.appendChild(labelEl)

    const inner = document.createElement("div")
    inner.className = "relative"

    const prefix = document.createElement("span")
    prefix.className = "absolute inset-y-0 left-0 pl-3 flex items-center text-gray-400 text-sm"
    prefix.textContent = "$"
    inner.appendChild(prefix)

    const input = document.createElement("input")
    input.type = "number"
    input.step = "0.01"
    input.min = "0"
    input.name = "product[pricing][price_points][][cost]"
    input.value = value
    input.placeholder = "0.00"
    input.className = "w-full rounded-lg border-gray-300 focus:border-theme-500 focus:ring-theme-500 pl-7"
    inner.appendChild(input)

    wrap.appendChild(inner)
    return wrap
  }

  _buildRemoveCell() {
    const wrap = document.createElement("div")
    wrap.className = "col-span-2 flex justify-end"

    const link = document.createElement("button")
    link.type = "button"
    link.textContent = "Remove"
    link.className = "text-xs text-gray-400 hover:text-red-500"
    link.setAttribute("data-action", "click->product-pricing#removePoint")
    wrap.appendChild(link)

    return wrap
  }
}
