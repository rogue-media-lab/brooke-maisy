module Pdf
  class WorkOrderInternalPdf < Base
    private

    def draw_body(pdf)
      pdf.move_down 20

      pdf.text "INTERNAL WORK ORDER", style: :bold, size: 16, align: :center, color: "776B63"
      pdf.move_down 6
      pdf.text "INTERNAL USE ONLY — Do not share with Client. Contains measurements and cost details.", size: 9, align: :center, color: "CC0000"
      pdf.move_down 16

      draw_project_info(pdf)
      pdf.move_down 12

      draw_measurements_table(pdf)
      pdf.move_down 12

      draw_cost_tracking(pdf)
      pdf.move_down 12

      draw_site_notes(pdf)
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
      pdf.text "Estimated Start Date: __________________     Estimated Completion Date: __________________", size: 10
      pdf.move_down 4
      pdf.text "Subcontractor / Installer (if applicable): ________________________________________________", size: 10
    end

    def draw_measurements_table(pdf)
      pdf.text "Measurements & Product Specifications", style: :bold, size: 11, color: "776B63"
      pdf.move_down 6

      data = [ [ "Room", "Product / Item", "Width", "Height", "Qty", "Install Notes" ] ]

      @quote.quote_line_items.ordered.each do |item|
        data << [
          item.location || "—",
          item.product&.name || item.description || "—",
          item.width ? "#{item.width}\"" : "—",
          item.height ? "#{item.height}\"" : "—",
          item.quantity.to_s,
          item.notes || ""
        ]
      end

      pdf.table(data, width: pdf.bounds.width, cell_style: { size: 9, borders: [ :bottom ], border_color: "CCCCCC" }) do |table|
        table.row(0).font_style = :bold
        table.row(0).borders = [ :bottom ]
        table.row(0).border_width = 1
      end
    end

    def draw_cost_tracking(pdf)
      pdf.text "Internal Cost Tracking", style: :bold, size: 11, color: "776B63"
      pdf.move_down 6
      pdf.text "Supplier / Vendor Cost (materials): #{currency(@calculator[:total_cost])}", size: 10
      pdf.move_down 4
      pdf.text "Labor / Installation Cost: ______________________", size: 10
      pdf.move_down 4
      markup = QuoteCalculator::DEFAULT_MARKUP * 100
      pdf.text "Markup Applied: #{markup.round(0)}%", size: 10
      pdf.move_down 4
      pdf.text "Client-Facing Total (from client Work Order): #{currency(@calculator[:grand_total])}", size: 10
      pdf.move_down 4
      pdf.text "Estimated Margin: #{currency(@calculator[:gross_profit])} (#{@calculator[:profit_margin_pct]}%)", size: 10
    end

    def draw_site_notes(pdf)
      pdf.text "Site & Access Notes", style: :bold, size: 11, color: "776B63"
      pdf.move_down 6
      pdf.text "Access instructions, pets, gate codes, parking, HOA restrictions, hazards noted at site visit, etc.:", size: 9
      pdf.move_down 16
      pdf.text "Internal Notes:", style: :bold, size: 10, color: "776B63"
      pdf.move_down 6
      pdf.text @quote.notes || "", size: 9
    end
  end
end
