module Pdf
  class InvoicePdf < Base
    private

    def draw_body(pdf)
      pdf.move_down 20

      pdf.text "INVOICE", style: :bold, size: 16, align: :center, color: "776B63"
      pdf.move_down 16

      draw_from_to(pdf)
      pdf.move_down 12

      draw_invoice_meta(pdf)
      pdf.move_down 12

      draw_line_items(pdf)
      pdf.move_down 12

      draw_totals(pdf)
      pdf.move_down 20

      draw_payment_instructions(pdf)
    end

    def draw_from_to(pdf)
      pdf.bounding_box([ 0, pdf.cursor ], width: pdf.bounds.width / 2 - 10, height: 80) do
        pdf.text "From:", style: :bold, size: 9, color: "776B63"
        pdf.text BUSINESS[:name], size: 9
        pdf.text BUSINESS[:address], size: 9
        pdf.text BUSINESS[:email], size: 9
        pdf.text BUSINESS[:phone], size: 9
      end

      pdf.bounding_box([ pdf.bounds.width / 2 + 10, pdf.cursor + 80 ], width: pdf.bounds.width / 2 - 10, height: 80) do
        pdf.text "Bill To:", style: :bold, size: 9, color: "776B63"
        pdf.text client_name, size: 9
        pdf.text @client&.address || "", size: 9
        pdf.text "Project Location: #{project_location}", size: 9
      end
    end

    def draw_invoice_meta(pdf)
      invoice_num = "INV-#{@quote.id}-#{Date.current.strftime('%Y%m%d')}"
      due_date = 30.days.from_now
      pdf.text "Invoice #: #{invoice_num}       Invoice Date: #{formatted_date}   Payment Due Date: #{formatted_date(due_date)}", size: 10
      pdf.move_down 4
      pdf.text "Related Work Order / Change Order #: WO-#{@quote.id}", size: 10
    end

    def draw_line_items(pdf)
      pdf.text "Line Items", style: :bold, size: 11, color: "776B63"
      pdf.move_down 6

      data = [ [ "Room", "Description", "Qty", "Unit Price", "Line Total" ] ]
      calc_by_id = @calculator[:line_items].index_by { |c| c[:id] }

      @quote.quote_line_items.ordered.each do |item|
        calc = calc_by_id[item.id] || {}
        data << [
          item.location || "—",
          item.product&.name || item.description || "—",
          item.quantity.to_s,
          currency(calc[:adjusted_retail] || 0),
          currency(calc[:line_total] || 0)
        ]
      end

      pdf.table(data, width: pdf.bounds.width, cell_style: { size: 9, borders: [ :bottom ], border_color: "CCCCCC" }) do |table|
        table.row(0).font_style = :bold
        table.row(0).borders = [ :bottom ]
        table.row(0).border_width = 1
        table.columns(2..4).align = :right
      end
    end

    def draw_totals(pdf)
      total_paid = @quote.payments.sum(&:amount)

      data = [
        [ "", "Subtotal:", currency(@calculator[:subtotal]) ],
        [ "", "Tax:", currency(@calculator[:tax_amount]) ],
        [ "", "Less: Deposits / Prior Payments Received:", currency(total_paid) ],
        [ "", "Balance Due:", currency(@calculator[:grand_total] - total_paid) ]
      ]

      pdf.table(data, width: 300, position: :right, cell_style: { size: 9, borders: [ :bottom ], border_color: "CCCCCC" }) do |table|
        table.columns(0).align = :right
        table.columns(1).align = :right
        table.columns(2).align = :right
        table.row(-1).font_style = :bold
        table.row(-1).borders = [ :top, :bottom ]
        table.row(-1).border_width = 1
      end
    end

    def draw_payment_instructions(pdf)
      pdf.text "Payment Instructions", style: :bold, size: 11, color: "776B63"
      pdf.move_down 6
      pdf.text "Brooke & Maisy Interior Designs, LLC accepts payment by cash, check, or credit card. Checks payable to Amanda Nelson. A processing fee may apply to credit card payments where permitted by law.", size: 9
      pdf.move_down 4
      pdf.text "Amounts not paid by the due date accrue interest at 1% per month, consistent with Section 2 of the Design & Installation Services Agreement.", size: 9
      pdf.move_down 12
      pdf.text "Thank You", style: :bold, size: 11, color: "776B63"
      pdf.text "Thank you for the opportunity to work on your home.", size: 9, style: :italic
    end
  end
end
