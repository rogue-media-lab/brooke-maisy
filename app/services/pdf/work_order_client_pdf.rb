module Pdf
  class WorkOrderClientPdf < Base
    private

    def draw_body(pdf)
      pdf.move_down 20

      pdf.text "WORK ORDER", style: :bold, size: 16, align: :center, color: "776B63"
      pdf.move_down 6
      pdf.text "This Work Order is incorporated into and made part of the Design & Installation Services Agreement between Brooke & Maisy Interior Designs, LLC and Client.", size: 9, align: :center
      pdf.move_down 16

      draw_project_info(pdf)
      pdf.move_down 12

      draw_scope_of_work(pdf)
      pdf.move_down 12

      draw_products_table(pdf)
      pdf.move_down 12

      draw_payment_schedule(pdf)
      pdf.move_down 20

      draw_approval(pdf)
    end

    def draw_project_info(pdf)
      pdf.text "Project Information", style: :bold, size: 11, color: "776B63"
      pdf.move_down 6
      pdf.text "Client Name: #{client_name}                Date: #{formatted_date}", size: 10
      pdf.move_down 4
      pdf.text "Project Location: #{project_location}", size: 10
      pdf.move_down 4
      contact = [ @client&.phone, @client&.email ].compact.join(" · ")
      pdf.text "Project Contact Phone / Email: #{contact.presence || '____________________'}", size: 10
      pdf.move_down 4
      pdf.text "Estimated Start Date: __________________             Estimated Completion Date: __________________", size: 10
    end

    def draw_scope_of_work(pdf)
      pdf.text "Scope of Work", style: :bold, size: 11, color: "776B63"
      pdf.move_down 6
      scope = @quote.quote_line_items.group_by(&:location).map do |location, items|
        room_label = location || "General"
        products = items.map { |i| i.product&.name || i.description }.compact.join(", ")
        "#{room_label}: #{products}"
      end.join("\n")
      pdf.text scope.presence || "Describe the rooms and scope of the project:", size: 9
    end

    def draw_products_table(pdf)
      pdf.text "Products & Pricing", style: :bold, size: 11, color: "776B63"
      pdf.move_down 6

      data = [ [ "Room", "Product / Item", "Qty", "Unit Price", "Line Total" ] ]
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

      data << [ "", "", "", "Subtotal:", currency(@calculator[:subtotal]) ]
      data << [ "", "", "", "Tax:", currency(@calculator[:tax_amount]) ]
      data << [ "", "", "", "Total:", currency(@calculator[:grand_total]) ]

      pdf.table(data, width: pdf.bounds.width, cell_style: { size: 9, borders: [ :bottom ], border_color: "CCCCCC" }) do |table|
        table.row(0).font_style = :bold
        table.row(0).borders = [ :bottom ]
        table.row(0).border_width = 1
        table.columns(2..4).align = :right
        table.row(-3).font_style = :bold
        table.row(-2).font_style = :bold
        table.row(-1).font_style = :bold
      end
    end

    def draw_payment_schedule(pdf)
      pdf.text "Payment Schedule", style: :bold, size: 11, color: "776B63"
      pdf.move_down 6
      deposit_pct = @quote.deposit_percentage ? "#{@quote.deposit_percentage}%" : "50%"
      pdf.text "Design Retainer Due at Signing: #{currency(@calculator[:deposit_amount])} (#{deposit_pct})", size: 10
      pdf.move_down 4
      pdf.text "Deposit Due Before Ordering: #{currency(@calculator[:deposit_amount])} (#{deposit_pct})", size: 10
      pdf.move_down 4
      pdf.text "Balance Due at Completion: #{currency(@calculator[:balance_due])}", size: 10
    end

    def draw_approval(pdf)
      pdf.text "Client Approval", style: :bold, size: 11, color: "776B63"
      pdf.move_down 6
      pdf.text "By signing below, Client approves the products, pricing, and scope of work described in this Work Order, subject to the terms of the Design & Installation Services Agreement.", size: 9
      pdf.move_down 24
      pdf.text "Client Signature: _________________________________________           Date: __________________", size: 10
      pdf.move_down 20
      pdf.text "Designer Signature: _______________________________________            Date: __________________", size: 10
    end
  end
end
